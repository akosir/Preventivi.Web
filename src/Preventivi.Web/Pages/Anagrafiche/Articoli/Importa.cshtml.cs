using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

[Authorize(Policy = AutorizzazioneApplicazione.PolicyAnagrafiche)]
[RequestSizeLimit(4 * 1024 * 1024)]
[RequestFormLimits(ValueLengthLimit = 3 * 1024 * 1024, MultipartBodyLengthLimit = 4 * 1024 * 1024)]
public sealed class ImportaModel(
    IArticoloRepository articoli,
    IArticoliImportazioneService importazione,
    ArticoliExcelService excel,
    IDataProtectionProvider protezione) : PageModel
{
    private readonly ITimeLimitedDataProtector _protezione = protezione
        .CreateProtector("Preventivi.Articoli.Importazione.Anteprima.v1").ToTimeLimitedDataProtector();
    [BindProperty] public ArticoliImportazioneFormModel Dati { get; set; } = new();
    public IReadOnlyList<ArticoloImportazioneRiga> Righe { get; private set; } = [];
    public IReadOnlyList<ArticoliImportazioneErrore> Errori { get; private set; } = [];
    public string? NomeFile { get; private set; }
    public bool AnteprimaDisponibile { get; private set; }

    public void OnGet() { }

    public async Task<IActionResult> OnGetModelloAsync(CancellationToken cancellationToken)
    {
        var clienti = await articoli.GetClientiAsync(cancellationToken: cancellationToken);
        return File(excel.CreaModello(clienti), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Importazione_Articoli.xlsx");
    }

    public async Task<IActionResult> OnPostAnteprimaAsync(CancellationToken cancellationToken)
    {
        AnteprimaDisponibile = false;
        Dati.TokenAnteprima = Dati.ContenutoBase64 = string.Empty;
        ModelState.Remove("Dati.TokenAnteprima");
        ModelState.Remove("Dati.ContenutoBase64");
        var file = Dati.File;
        if (file is null || file.Length == 0 || file.Length > ArticoliExcelService.DimensioneMassimaFile ||
            !string.Equals(Path.GetExtension(file.FileName), ".xlsx", StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError("Dati.File", "Selezionare un file .xlsx non vuoto, fino a 2 MB.");
            return Page();
        }
        if (string.IsNullOrWhiteSpace(User.Identity?.Name)) return Forbid();
        using var stream = new MemoryStream();
        // La lunghezza dichiarata non e usata come unica barriera di lettura.
        using (var input = file.OpenReadStream())
        {
            var buffer = new byte[81920];
            int letti;
            while ((letti = await input.ReadAsync(buffer, cancellationToken)) > 0)
            {
                if (stream.Length + letti > ArticoliExcelService.DimensioneMassimaFile)
                {
                    ModelState.AddModelError("Dati.File", "Il file supera 2 MB.");
                    return Page();
                }
                await stream.WriteAsync(buffer.AsMemory(0, letti), cancellationToken);
            }
        }
        var contenuto = stream.ToArray();
        NomeFile = Path.GetFileName(file.FileName.Replace('\\', '/'));
        if (NomeFile.Length > 260)
        {
            ModelState.AddModelError("Dati.File", "Il nome del file supera 260 caratteri.");
            return Page();
        }
        await AnalizzaAsync(contenuto, cancellationToken);
        if (Errori.Count == 0 && Righe.Count > 0 && ModelState.IsValid)
        {
            Dati.ContenutoBase64 = Convert.ToBase64String(contenuto);
            Dati.TokenAnteprima = _protezione.Protect(JsonSerializer.Serialize(
                new Anteprima(ArticoliExcelService.CalcolaImpronta(contenuto), NomeFile, User.Identity.Name)), TimeSpan.FromMinutes(20));
            AnteprimaDisponibile = true;
        }
        return Page();
    }

    public async Task<IActionResult> OnPostApplicaAsync(CancellationToken cancellationToken)
    {
        AnteprimaDisponibile = false;
        if (string.IsNullOrWhiteSpace(User.Identity?.Name)) return Forbid();
        if (!ModelState.IsValid || string.IsNullOrWhiteSpace(Dati.TokenAnteprima) ||
            string.IsNullOrWhiteSpace(Dati.ContenutoBase64) || Dati.ContenutoBase64.Length > 2796204 ||
            Dati.TokenAnteprima.Length > 8192)
            return AnteprimaNonValida();
        byte[] contenuto;
        Anteprima? anteprima;
        try
        {
            anteprima = JsonSerializer.Deserialize<Anteprima>(_protezione.Unprotect(Dati.TokenAnteprima));
            contenuto = Convert.FromBase64String(Dati.ContenutoBase64);
        }
        catch (Exception e) when (e is CryptographicException or FormatException or JsonException)
        {
            return AnteprimaNonValida();
        }
        if (anteprima is null || anteprima.Utente != User.Identity.Name ||
            anteprima.Impronta != ArticoliExcelService.CalcolaImpronta(contenuto))
            return AnteprimaNonValida();
        NomeFile = anteprima.NomeFile;
        var analisi = excel.Analizza(contenuto);
        Righe = analisi.Righe;
        Errori = analisi.Errori;
        if (!analisi.Valida) return AnteprimaNonValida();
        try
        {
            var numero = await importazione.ApplicaAsync(new(Guid.NewGuid(), NomeFile,
                anteprima.Impronta, User.Identity.Name, Righe), cancellationToken);
            TempData["MessaggioSuccesso"] = $"Importazione completata: {numero} nuovi articoli attivi. Nessun articolo esistente e stato modificato.";
            return RedirectToPage("./Index");
        }
        catch (ArticoliImportazioneException e)
        {
            ModelState.AddModelError(string.Empty, e.Message);
            // Rivalidare restituisce i dettagli per riga dopo un cambiamento
            // concorrente; la conferma precedente non viene riproposta.
            await AnalizzaAsync(contenuto, cancellationToken);
            Dati.TokenAnteprima = string.Empty;
            ModelState.Remove("Dati.TokenAnteprima");
            return Page();
        }
    }

    private async Task AnalizzaAsync(byte[] contenuto, CancellationToken cancellationToken)
    {
        var analisi = excel.Analizza(contenuto);
        Righe = analisi.Righe;
        Errori = analisi.Errori.Count > 0 ? analisi.Errori : await importazione.ValidaAsync(Righe, cancellationToken);
    }

    private PageResult AnteprimaNonValida()
    {
        Dati.TokenAnteprima = Dati.ContenutoBase64 = string.Empty;
        ModelState.Remove("Dati.TokenAnteprima");
        ModelState.Remove("Dati.ContenutoBase64");
        ModelState.AddModelError(string.Empty, "Anteprima assente, modificata o scaduta. Caricare il file e generare una nuova anteprima.");
        return Page();
    }

    public sealed record Anteprima(string Impronta, string NomeFile, string Utente);
}

using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni;

[Authorize(Policy = AutorizzazioneApplicazione.PolicyAnagrafiche)]
[RequestSizeLimit(4 * 1024 * 1024)]
[RequestFormLimits(ValueLengthLimit = 3 * 1024 * 1024, MultipartBodyLengthLimit = 4 * 1024 * 1024)]
public sealed class ImportaModel(
    IDistintaBaseRepository repository,
    IDistintaBaseApplicationService applicationService,
    DistintaBaseExcelService excel,
    ILogger<ImportaModel> logger,
    IArticoloRepository articoli,
    IDataProtectionProvider protezione) : PageModel
{
    private readonly ITimeLimitedDataProtector _protezione = protezione
        .CreateProtector("Preventivi.Distinte.Importazione.Anteprima.v1").ToTimeLimitedDataProtector();

    [BindProperty] public DistintaImportazioneFormModel Dati { get; set; } = new();
    public DistintaRevisioneDettaglio? Distinta { get; private set; }
    public DistintaImportazioneAnalisi? Analisi { get; private set; }
    public bool DistintaVuota { get; private set; }
    public bool PuoConfermare { get; private set; }
    public string? NomeFile { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ?? Page();

    public Task<IActionResult> OnGetModelloAsync(int id, CancellationToken cancellationToken) =>
        ScaricaModelloAsync(id, false, cancellationToken);

    public Task<IActionResult> OnGetModelloAvanzatoAsync(int id, CancellationToken cancellationToken) =>
        ScaricaModelloAsync(id, true, cancellationToken);

    private async Task<IActionResult> ScaricaModelloAsync(int id, bool avanzato, CancellationToken cancellationToken)
    {
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;
        var lookups = await CaricaLookupsAsync(cancellationToken);
        return File(avanzato ? excel.CreaModello(lookups.Tipi, lookups.Materiali, lookups.Lavorazioni)
                : excel.CreaModelloSemplificato(lookups.Tipi, lookups.Materiali, lookups.Lavorazioni),
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"ImportazioneDistinta_{SanificaNomeFile(Distinta!.CodiceArticolo)}{(avanzato ? "_Avanzato" : "")}.xlsx");
    }

    public async Task<IActionResult> OnPostAnteprimaAsync(int id, CancellationToken cancellationToken)
    {
        AnnullaConferma();
        Analisi = null;
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;
        if (!DistintaVuota)
            return Errore("L'importazione e consentita soltanto sulla distinta corrente priva di nodi.");
        if (string.IsNullOrWhiteSpace(User.Identity?.Name)) return Forbid();

        var file = Dati.File;
        if (file is null || file.Length == 0 || file.Length > DistintaBaseExcelService.DimensioneMassimaFile ||
            !string.Equals(Path.GetExtension(file.FileName), ".xlsx", StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError("Dati.File", "Selezionare un file .xlsx non vuoto, fino a 2 MB.");
            return Page();
        }
        using var stream = new MemoryStream();
        using (var input = file.OpenReadStream())
        {
            var buffer = new byte[81920];
            int letti;
            while ((letti = await input.ReadAsync(buffer, cancellationToken)) > 0)
            {
                if (stream.Length + letti > DistintaBaseExcelService.DimensioneMassimaFile)
                    return Errore("Il file supera 2 MB.");
                await stream.WriteAsync(buffer.AsMemory(0, letti), cancellationToken);
            }
        }
        var contenuto = stream.ToArray();
        NomeFile = Path.GetFileName(file.FileName.Replace('\\', '/'));
        if (NomeFile.Length > 260) return Errore("Il nome del file supera 260 caratteri.");

        var lookups = await CaricaLookupsAsync(cancellationToken);
        Analisi = excel.Analizza(contenuto, lookups.Tipi, lookups.Materiali, lookups.Lavorazioni);
        if (Analisi.Valida && ModelState.IsValid)
        {
            Dati.ContenutoBase64 = Convert.ToBase64String(contenuto);
            Dati.TokenAnteprima = _protezione.Protect(JsonSerializer.Serialize(new Anteprima(
                Guid.NewGuid(), id, Distinta!.IdArticolo, NomeFile,
                DistintaBaseExcelService.CalcolaImpronta(contenuto),
                Convert.ToBase64String(Distinta.VersioneRiga), User.Identity.Name,
                DistintaBaseExcelService.CalcolaImprontaAnalisi(Analisi))), TimeSpan.FromMinutes(20));
            PuoConfermare = true;
        }
        return Page();
    }

    public async Task<IActionResult> OnPostApplicaAsync(int id, CancellationToken cancellationToken)
    {
        PuoConfermare = false;
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;
        if (!DistintaVuota) return Errore("La distinta corrente contiene gia dei nodi. Nessun dato e stato importato.");
        if (string.IsNullOrWhiteSpace(User.Identity?.Name)) return Forbid();
        if (!ModelState.IsValid || string.IsNullOrWhiteSpace(Dati.TokenAnteprima) ||
            Dati.TokenAnteprima.Length > 8192 || string.IsNullOrWhiteSpace(Dati.ContenutoBase64) ||
            Dati.ContenutoBase64.Length > 2796204)
            return AnteprimaNonValida();

        Anteprima? anteprima;
        byte[] contenuto, versione;
        try
        {
            anteprima = JsonSerializer.Deserialize<Anteprima>(_protezione.Unprotect(Dati.TokenAnteprima));
            contenuto = Convert.FromBase64String(Dati.ContenutoBase64);
            versione = anteprima is null ? [] : Convert.FromBase64String(anteprima.VersioneRiga);
        }
        catch (Exception e) when (e is CryptographicException or JsonException or FormatException)
        {
            return AnteprimaNonValida();
        }
        if (anteprima is null || anteprima.IdImportazione == Guid.Empty ||
            anteprima.IdDistinta != id || anteprima.IdArticolo != Distinta!.IdArticolo ||
            anteprima.Utente != User.Identity.Name || anteprima.Impronta != DistintaBaseExcelService.CalcolaImpronta(contenuto))
            return AnteprimaNonValida();
        if (versione.Length != 8 || !versione.SequenceEqual(Distinta.VersioneRiga))
            return Errore("La distinta corrente e cambiata dopo l'anteprima. Generare una nuova anteprima.");
        NomeFile = anteprima.NomeFile;

        var lookups = await CaricaLookupsAsync(cancellationToken);
        Analisi = excel.Analizza(contenuto, lookups.Tipi, lookups.Materiali, lookups.Lavorazioni);
        if (!Analisi.Valida)
            return Errore("I dati non superano piu la validazione. Correggere il file e generare una nuova anteprima.");
        if (string.IsNullOrWhiteSpace(anteprima.ImprontaAnalisi) ||
            anteprima.ImprontaAnalisi != DistintaBaseExcelService.CalcolaImprontaAnalisi(Analisi))
            return Errore("I valori proposti dall'anagrafica sono cambiati dopo l'anteprima. Generare una nuova anteprima per verificarli.");
        try
        {
            await applicationService.ImportaAsync(new DistintaImportazioneRequest
            {
                IdImportazione = anteprima.IdImportazione, IdRevisioneDistinta = id,
                NomeFile = NomeFile, ImprontaSha256 = anteprima.Impronta,
                Utente = User.Identity.Name, VersioneRiga = versione,
                Nodi = Analisi.Nodi, Materiali = Analisi.Materiali, Lavorazioni = Analisi.Lavorazioni
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = $"Importazione completata: {Analisi.Nodi.Count} nodi, {Analisi.Materiali.Count} materiali e {Analisi.Lavorazioni.Count} lavorazioni.";
            return RedirectToPage("../Dettaglio", new { idArticolo = Distinta.IdArticolo });
        }
        catch (SqlException e) when (DistinteSqlErrori.Gestito(e.Number) || e.Number is 2601 or 2627 or 1205)
        {
            logger.LogWarning(e, "Importazione distinta corrente {Id} rifiutata", id);
            return Errore(e.Number is 2601 or 2627 or 1205
                ? "I dati sono cambiati durante l'importazione. Generare una nuova anteprima; nessun dato e stato importato."
                : DistinteSqlErrori.Messaggio(e.Number));
        }
    }

    private async Task<IActionResult?> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return NotFound();
        Distinta = await repository.GetRevisioneAsync(id, cancellationToken);
        if (Distinta is null) return NotFound();
        if (!Distinta.Modificabile) return Forbid();
        var articolo = await articoli.GetDettaglioAsync(Distinta.IdArticolo, cancellationToken);
        if (articolo?.Attivo != true) return Forbid();
        DistintaVuota = (await repository.GetNodiAsync(id, cancellationToken)).Count == 0;
        return null;
    }

    private async Task<(IReadOnlyList<TipoNodoDistintaLookupItem> Tipi,
        IReadOnlyList<DistintaMaterialeLookupItem> Materiali,
        IReadOnlyList<DistintaLavorazioneLookupItem> Lavorazioni)> CaricaLookupsAsync(CancellationToken cancellationToken) =>
        (await repository.GetTipiNodoAsync(cancellationToken: cancellationToken),
         await repository.GetMaterialiLookupAsync(cancellationToken: cancellationToken),
         await repository.GetLavorazioniLookupAsync(cancellationToken: cancellationToken));

    private PageResult AnteprimaNonValida() =>
        Errore("Anteprima assente, modificata o scaduta. Caricare il file e generare una nuova anteprima.");

    private PageResult Errore(string messaggio)
    {
        AnnullaConferma();
        ModelState.AddModelError(string.Empty, messaggio);
        return Page();
    }

    private void AnnullaConferma()
    {
        PuoConfermare = false;
        Dati.TokenAnteprima = Dati.ContenutoBase64 = string.Empty;
        ModelState.Remove("Dati.TokenAnteprima");
        ModelState.Remove("Dati.ContenutoBase64");
    }

    private static string SanificaNomeFile(string valore)
    {
        var nonValidi = Path.GetInvalidFileNameChars().ToHashSet();
        var pulito = new string(valore.Where(c => !nonValidi.Contains(c)).ToArray()).Trim();
        return string.IsNullOrWhiteSpace(pulito) ? "Articolo" : pulito;
    }

    public sealed record Anteprima(Guid IdImportazione, int IdDistinta, int IdArticolo,
        string NomeFile, string Impronta, string VersioneRiga, string Utente, string? ImprontaAnalisi = null);
}

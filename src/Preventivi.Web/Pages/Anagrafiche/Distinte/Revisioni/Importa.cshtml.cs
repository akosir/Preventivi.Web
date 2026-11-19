using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni;

public sealed class ImportaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly IDistintaBaseApplicationService _applicationService;
    private readonly DistintaBaseExcelService _excel;
    private readonly ILogger<ImportaModel> _logger;

    public ImportaModel(
        IDistintaBaseRepository repository,
        IDistintaBaseApplicationService applicationService,
        DistintaBaseExcelService excel,
        ILogger<ImportaModel> logger)
    {
        _repository = repository;
        _applicationService = applicationService;
        _excel = excel;
        _logger = logger;
    }

    [BindProperty]
    public DistintaImportazioneFormModel Dati { get; set; } = new();

    public DistintaRevisioneDettaglio? Revisione { get; private set; }
    public DistintaImportazioneAnalisi? Analisi { get; private set; }
    public bool BozzaVuota { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        var risultato = await CaricaAsync(id, cancellationToken);
        return risultato ?? Page();
    }

    public async Task<IActionResult> OnGetModelloAsync(int id, CancellationToken cancellationToken)
    {
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;

        var lookups = await CaricaLookupsAsync(cancellationToken);
        var contenuto = _excel.CreaModello(lookups.Tipi, lookups.Materiali, lookups.Lavorazioni);
        var codice = SanificaNomeFile(Revisione!.CodiceArticolo);
        return File(
            contenuto,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"ImportazioneDistinta_{codice}_Rev{Revisione.NumeroRevisione}.xlsx");
    }

    public async Task<IActionResult> OnPostAnteprimaAsync(int id, CancellationToken cancellationToken)
    {
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;
        if (!BozzaVuota)
        {
            ModelState.AddModelError(string.Empty, "L'importazione è consentita soltanto su una revisione in bozza priva di nodi.");
            return Page();
        }

        var file = Dati.File;
        if (file is null || file.Length == 0)
        {
            ModelState.AddModelError(nameof(Dati.File), "Selezionare il file Excel da importare.");
            return Page();
        }
        if (!string.Equals(Path.GetExtension(file.FileName), ".xlsx", StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError(nameof(Dati.File), "Selezionare un file con estensione .xlsx.");
            return Page();
        }
        if (file.Length > DistintaBaseExcelService.DimensioneMassimaFile)
        {
            ModelState.AddModelError(nameof(Dati.File), "Il file supera la dimensione massima di 2 MB.");
            return Page();
        }

        byte[] contenuto;
        await using (var stream = new MemoryStream())
        {
            await file.CopyToAsync(stream, cancellationToken);
            contenuto = stream.ToArray();
        }

        var lookups = await CaricaLookupsAsync(cancellationToken);
        Analisi = _excel.Analizza(contenuto, lookups.Tipi, lookups.Materiali, lookups.Lavorazioni);
        Dati.NomeFile = Path.GetFileName(file.FileName);
        Dati.ImprontaSha256 = DistintaBaseExcelService.CalcolaImpronta(contenuto);
        Dati.VersioneRigaBase64 = Convert.ToBase64String(Revisione!.VersioneRiga);
        Dati.ContenutoBase64 = Analisi.Valida ? Convert.ToBase64String(contenuto) : string.Empty;
        ModelState.Remove(nameof(Dati.ContenutoBase64));
        ModelState.Remove(nameof(Dati.NomeFile));
        ModelState.Remove(nameof(Dati.ImprontaSha256));
        ModelState.Remove(nameof(Dati.VersioneRigaBase64));
        return Page();
    }

    public async Task<IActionResult> OnPostApplicaAsync(int id, CancellationToken cancellationToken)
    {
        var risultato = await CaricaAsync(id, cancellationToken);
        if (risultato is not null) return risultato;
        if (!BozzaVuota)
        {
            ModelState.AddModelError(string.Empty, "La revisione non è più vuota. Ricaricare la pagina.");
            return Page();
        }
        if (string.IsNullOrWhiteSpace(Dati.ContenutoBase64) ||
            string.IsNullOrWhiteSpace(Dati.NomeFile) ||
            string.IsNullOrWhiteSpace(Dati.ImprontaSha256) ||
            string.IsNullOrWhiteSpace(Dati.VersioneRigaBase64))
        {
            ModelState.AddModelError(string.Empty, "L'anteprima non è disponibile o è scaduta. Ricaricare il file.");
            return Page();
        }

        byte[] contenuto;
        byte[] versione;
        try
        {
            contenuto = Convert.FromBase64String(Dati.ContenutoBase64);
            versione = Convert.FromBase64String(Dati.VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "I dati dell'anteprima non sono validi. Ricaricare il file.");
            return Page();
        }
        if (versione.Length != 8)
        {
            ModelState.AddModelError(string.Empty, "La versione della revisione non è valida. Ricaricare il file.");
            return Page();
        }

        var impronta = DistintaBaseExcelService.CalcolaImpronta(contenuto);
        if (!string.Equals(impronta, Dati.ImprontaSha256, StringComparison.OrdinalIgnoreCase))
        {
            ModelState.AddModelError(string.Empty, "Il contenuto del file è cambiato dopo l'anteprima. Ricaricare il file.");
            return Page();
        }

        var lookups = await CaricaLookupsAsync(cancellationToken);
        Analisi = _excel.Analizza(contenuto, lookups.Tipi, lookups.Materiali, lookups.Lavorazioni);
        if (!Analisi.Valida)
        {
            Dati.ContenutoBase64 = string.Empty;
            ModelState.AddModelError(string.Empty, "Il file non supera più la validazione. Correggerlo e generare una nuova anteprima.");
            return Page();
        }

        try
        {
            await _applicationService.ImportaAsync(
                new DistintaImportazioneRequest
                {
                    IdImportazione = Guid.NewGuid(),
                    IdRevisioneDistinta = id,
                    NomeFile = Path.GetFileName(Dati.NomeFile),
                    ImprontaSha256 = impronta,
                    Utente = User.Identity?.Name ?? "Sistema",
                    VersioneRiga = versione,
                    Nodi = Analisi.Nodi,
                    Materiali = Analisi.Materiali,
                    Lavorazioni = Analisi.Lavorazioni
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = $"Importazione completata: {Analisi.Nodi.Count} nodi, {Analisi.Materiali.Count} materiali e {Analisi.Lavorazioni.Count} lavorazioni.";
            return RedirectToPage("../Dettaglio", new { idArticolo = Revisione!.IdArticolo, idRevisione = id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Importazione distinta {IdRevisione} rifiutata", id);
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<IActionResult?> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return NotFound();
        Revisione = await _repository.GetRevisioneAsync(id, cancellationToken);
        if (Revisione is null) return NotFound();
        if (!Revisione.Modificabile) return Forbid();
        BozzaVuota = (await _repository.GetNodiAsync(id, cancellationToken)).Count == 0;
        return null;
    }

    private async Task<(IReadOnlyList<TipoNodoDistintaLookupItem> Tipi, IReadOnlyList<DistintaMaterialeLookupItem> Materiali, IReadOnlyList<DistintaLavorazioneLookupItem> Lavorazioni)> CaricaLookupsAsync(CancellationToken cancellationToken) =>
        (
            await _repository.GetTipiNodoAsync(cancellationToken: cancellationToken),
            await _repository.GetMaterialiLookupAsync(cancellationToken: cancellationToken),
            await _repository.GetLavorazioniLookupAsync(cancellationToken: cancellationToken)
        );

    private static string SanificaNomeFile(string valore)
    {
        var nonValidi = Path.GetInvalidFileNameChars().ToHashSet();
        var pulito = new string(valore.Where(c => !nonValidi.Contains(c)).ToArray()).Trim();
        return string.IsNullOrWhiteSpace(pulito) ? "Articolo" : pulito;
    }
}

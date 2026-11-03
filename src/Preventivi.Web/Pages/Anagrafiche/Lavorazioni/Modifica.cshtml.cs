using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Lavorazioni;

public sealed class ModificaModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    private readonly ILogger<ModificaModel> _logger;
    public ModificaModel(IAnagraficheProduttiveRepository repository, ILogger<ModificaModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public LavorazioneFormModel Dati { get; set; } = new();
    public int IdLavorazione { get; private set; }
    private LavorazioneDettaglio? Corrente { get; set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new LavorazioneFormModel { CodiceLavorazione = Corrente!.CodiceLavorazione, Descrizione = Corrente.Descrizione, InternaEsterna = Corrente.InternaEsterna, CostoOrarioStandard = Corrente.CostoOrarioStandard, TempoSetupMinDefault = Corrente.TempoSetupMinDefault, TempoPezzoMinDefault = Corrente.TempoPezzoMinDefault, AcquistabileEsterna = Corrente.AcquistabileEsterna, IdFornitorePredefinito = Corrente.IdFornitorePredefinito, Note = Corrente.Note, VersioneRigaBase64 = Convert.ToBase64String(Corrente.VersioneRiga) };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Valida();
        var versione = LeggiVersione();
        if (!ModelState.IsValid) return Page();
        try
        {
            await _repository.AggiornaLavorazioneAsync(new LavorazioneUpdateModel { IdLavorazione = id, CodiceLavorazione = Dati.CodiceLavorazione, Descrizione = Dati.Descrizione, InternaEsterna = Dati.InternaEsterna, CostoOrarioStandard = Dati.CostoOrarioStandard, TempoSetupMinDefault = Dati.TempoSetupMinDefault, TempoPezzoMinDefault = Dati.TempoPezzoMinDefault, AcquistabileEsterna = Dati.AcquistabileEsterna, IdFornitorePredefinito = Dati.IdFornitorePredefinito, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Lavorazione aggiornata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (AnagraficheProduttiveSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento lavorazione {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, AnagraficheProduttiveSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }
    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        IdLavorazione = id;
        Corrente = await _repository.GetLavorazioneAsync(id, cancellationToken);
        if (Corrente is null) return false;
        ViewData["Fornitori"] = await _repository.GetFornitoriAsync(Corrente.IdFornitorePredefinito, cancellationToken);
        return true;
    }
    private void Valida()
    {
        if (Dati.InternaEsterna is not ("Interna" or "Esterna")) ModelState.AddModelError("Dati.InternaEsterna", "Selezionare una tipologia valida.");
        if (!Dati.AcquistabileEsterna && Dati.IdFornitorePredefinito.HasValue) ModelState.AddModelError("Dati.IdFornitorePredefinito", "Il fornitore e ammesso soltanto per lavorazioni acquistabili esternamente.");
    }
    private byte[] LeggiVersione()
    {
        try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; }
    }
}

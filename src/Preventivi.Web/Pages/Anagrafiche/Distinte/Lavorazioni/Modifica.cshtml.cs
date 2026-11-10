using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Lavorazioni;

public sealed class ModificaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository; private readonly IAllegatoRepository _allegati; private readonly ILogger<ModificaModel> _logger;
    public ModificaModel(IDistintaBaseRepository repository, IAllegatoRepository allegati, ILogger<ModificaModel> logger) { _repository = repository; _allegati = allegati; _logger = logger; }
    [BindProperty] public DistintaLavorazioneFormModel Dati { get; set; } = new(); public DistintaLavorazioneDettaglio? Lavorazione { get; private set; } public DistintaNodoDettaglio? Nodo { get; private set; } public AllegatiGridModel Allegati { get; private set; } = new();
    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new DistintaLavorazioneFormModel { IdLavorazione = Lavorazione!.IdLavorazione, Sequenza = Lavorazione.Sequenza, TempoSetupMin = Lavorazione.TempoSetupMin, TempoPezzoMin = Lavorazione.TempoPezzoMin, CostoOrario = Lavorazione.CostoOrario, CostoFisso = Lavorazione.CostoFisso, Note = Lavorazione.Note, VersioneRigaBase64 = Convert.ToBase64String(Lavorazione.VersioneRiga) };
        return Page();
    }
    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound(); var versione = LeggiVersione(); if (!ModelState.IsValid) return Page();
        try { await _repository.AggiornaLavorazioneAsync(new DistintaLavorazioneUpdateModel { IdDistintaLavorazione = id, IdNodoDistinta = Lavorazione!.IdNodoDistinta, IdLavorazione = Dati.IdLavorazione!.Value, Sequenza = Dati.Sequenza, TempoSetupMin = Dati.TempoSetupMin, TempoPezzoMin = Dati.TempoPezzoMin, CostoOrario = Dati.CostoOrario, CostoFisso = Dati.CostoFisso, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken); TempData["MessaggioSuccesso"] = "Lavorazione distinta aggiornata correttamente."; return RedirectToPage(new { id }); }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number)) { _logger.LogWarning(exception, "Aggiornamento lavorazione distinta {Id} rifiutato", id); ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false; Lavorazione = await _repository.GetLavorazioneAsync(id, cancellationToken); if (Lavorazione is null) return false; Nodo = await _repository.GetNodoAsync(Lavorazione.IdNodoDistinta, cancellationToken); if (Nodo is null) return false;
        ViewData["LavorazioniLookup"] = await _repository.GetLavorazioniLookupAsync(Lavorazione.IdLavorazione, cancellationToken);
        Allegati = new AllegatiGridModel { Allegati = await _allegati.GetElencoAsync(AllegatoEntita.DistintaLavorazioni, id, cancellationToken), ReturnUrl = Url.Page("/Anagrafiche/Distinte/Lavorazioni/Modifica", new { id }) };
        return true;
    }
    private byte[] LeggiVersione() { try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); } catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; } }
}

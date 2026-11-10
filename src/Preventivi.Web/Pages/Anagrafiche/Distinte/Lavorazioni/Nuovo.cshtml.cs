using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Lavorazioni;

public sealed class NuovoModel : PageModel
{
    private readonly IDistintaBaseRepository _repository; private readonly ILogger<NuovoModel> _logger;
    public NuovoModel(IDistintaBaseRepository repository, ILogger<NuovoModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public DistintaLavorazioneFormModel Dati { get; set; } = new(); public DistintaNodoDettaglio? Nodo { get; private set; }
    public async Task<IActionResult> OnGetAsync(int idNodo, CancellationToken cancellationToken) => await CaricaAsync(idNodo, cancellationToken) ? Page() : NotFound();
    public async Task<IActionResult> OnPostAsync(int idNodo, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idNodo, cancellationToken)) return NotFound(); if (!ModelState.IsValid) return Page();
        try { var id = await _repository.CreaLavorazioneAsync(new DistintaLavorazioneCreateModel { IdNodoDistinta = idNodo, IdLavorazione = Dati.IdLavorazione!.Value, Sequenza = Dati.Sequenza, TempoSetupMin = Dati.TempoSetupMin, TempoPezzoMin = Dati.TempoPezzoMin, CostoOrario = Dati.CostoOrario, CostoFisso = Dati.CostoFisso, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema" }, cancellationToken); TempData["MessaggioSuccesso"] = "Lavorazione aggiunta alla distinta."; return RedirectToPage("./Modifica", new { id }); }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number)) { _logger.LogWarning(exception, "Inserimento lavorazione distinta rifiutato"); ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int idNodo, CancellationToken cancellationToken) { if (idNodo <= 0) return false; Nodo = await _repository.GetNodoAsync(idNodo, cancellationToken); if (Nodo is null) return false; ViewData["LavorazioniLookup"] = await _repository.GetLavorazioniLookupAsync(cancellationToken: cancellationToken); return true; }
}

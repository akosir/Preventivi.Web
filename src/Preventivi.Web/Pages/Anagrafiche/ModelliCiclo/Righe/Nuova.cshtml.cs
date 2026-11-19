using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo.Righe;

public sealed class NuovaModel(IModelloCicloRepository repository, ILogger<NuovaModel> logger) : PageModel
{
    [BindProperty] public ModelloCicloRigaFormModel Dati { get; set; } = new();
    public ModelloCicloDettaglio? ModelloCiclo { get; private set; }
    public async Task<IActionResult> OnGetAsync(int idModelloCiclo, CancellationToken cancellationToken) => await CaricaAsync(idModelloCiclo, null, cancellationToken) ? Page() : NotFound();
    public async Task<IActionResult> OnPostAsync(int idModelloCiclo, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idModelloCiclo, null, cancellationToken)) return NotFound(); if (!ModelState.IsValid) return Page();
        try { await repository.CreaRigaAsync(Mappa(idModelloCiclo), cancellationToken); TempData["MessaggioSuccesso"] = "Riga del modello ciclo creata correttamente."; return RedirectToPage("../Dettaglio", new { id = idModelloCiclo }); }
        catch (SqlException ex) when (ModelliCicloSqlErrori.Gestito(ex.Number)) { logger.LogWarning(ex, "Creazione riga modello ciclo {Id} rifiutata", idModelloCiclo); ModelState.AddModelError(string.Empty, ModelliCicloSqlErrori.Messaggio(ex.Number)); return Page(); }
    }
    private ModelloCicloRigaCreateModel Mappa(int id) => new() { IdModelloCiclo = id, RigaNr = Dati.RigaNr, Sequenza = Dati.Sequenza, IdLavorazione = Dati.IdLavorazione, TempoSetupMin = Dati.TempoSetupMin, TempoPezzoMin = Dati.TempoPezzoMin, CostoOrario = Dati.CostoOrario, CostoFisso = Dati.CostoFisso, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema" };
    private async Task<bool> CaricaAsync(int id, int? idLavorazione, CancellationToken token) { ModelloCiclo = await repository.GetDettaglioAsync(id, token); if (ModelloCiclo is null) return false; ViewData["Lavorazioni"] = await repository.GetLavorazioniAsync(idLavorazione, token); return true; }
}

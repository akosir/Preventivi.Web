using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo;

public sealed class ModificaModel(IModelloCicloRepository repository, ILogger<ModificaModel> logger) : PageModel
{
    [BindProperty] public ModelloCicloFormModel Dati { get; set; } = new();
    public int IdModelloCiclo { get; private set; }
    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        var corrente = await repository.GetDettaglioAsync(id, cancellationToken); if (corrente is null) return NotFound(); IdModelloCiclo = id;
        Dati = new() { CodiceModelloCiclo = corrente.CodiceModelloCiclo, Descrizione = corrente.Descrizione, Note = corrente.Note, VersioneRigaBase64 = Convert.ToBase64String(corrente.VersioneRiga) }; return Page();
    }
    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        IdModelloCiclo = id; if (await repository.GetDettaglioAsync(id, cancellationToken) is null) return NotFound();
        byte[] versione; try { versione = Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); } catch (FormatException) { versione = []; ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); }
        if (!ModelState.IsValid) return Page();
        try { await repository.AggiornaAsync(new ModelloCicloUpdateModel { IdModelloCiclo = id, CodiceModelloCiclo = Dati.CodiceModelloCiclo, Descrizione = Dati.Descrizione, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken); TempData["MessaggioSuccesso"] = "Modello ciclo aggiornato correttamente."; return RedirectToPage("./Dettaglio", new { id }); }
        catch (SqlException ex) when (ModelliCicloSqlErrori.Gestito(ex.Number)) { logger.LogWarning(ex, "Aggiornamento modello ciclo {Id} rifiutato", id); ModelState.AddModelError(string.Empty, ModelliCicloSqlErrori.Messaggio(ex.Number)); return Page(); }
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo;

public sealed class NuovoModel(IModelloCicloRepository repository, ILogger<NuovoModel> logger) : PageModel
{
    [BindProperty] public ModelloCicloFormModel Dati { get; set; } = new();
    public void OnGet() { }
    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await repository.CreaAsync(new ModelloCicloCreateModel { CodiceModelloCiclo = Dati.CodiceModelloCiclo, Descrizione = Dati.Descrizione, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema" }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Modello ciclo creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException ex) when (ModelliCicloSqlErrori.Gestito(ex.Number)) { logger.LogWarning(ex, "Creazione modello ciclo rifiutata"); ModelState.AddModelError(string.Empty, ModelliCicloSqlErrori.Messaggio(ex.Number)); return Page(); }
    }
}

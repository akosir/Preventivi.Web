using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Materiali;

public sealed class NuovoModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly ILogger<NuovoModel> _logger;
    public NuovoModel(IDistintaBaseRepository repository, ILogger<NuovoModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public DistintaMaterialeFormModel Dati { get; set; } = new();
    public DistintaNodoDettaglio? Nodo { get; private set; }
    public async Task<IActionResult> OnGetAsync(int idNodo, CancellationToken cancellationToken) => await CaricaAsync(idNodo, cancellationToken) ? Page() : NotFound();
    public async Task<IActionResult> OnPostAsync(int idNodo, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idNodo, cancellationToken)) return NotFound();
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await _repository.CreaMaterialeAsync(new DistintaMaterialeCreateModel { IdNodoDistinta = idNodo, IdMateriale = Dati.IdMateriale!.Value, Quantita = Dati.Quantita, CoeffScartoPerc = Dati.CoeffScartoPerc, CostoUnitario = Dati.CostoUnitario, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema" }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Materiale aggiunto alla distinta.";
            return RedirectToPage("./Modifica", new { id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number)) { _logger.LogWarning(exception, "Inserimento materiale distinta rifiutato"); ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int idNodo, CancellationToken cancellationToken) { if (idNodo <= 0) return false; Nodo = await _repository.GetNodoAsync(idNodo, cancellationToken); if (Nodo is null) return false; ViewData["MaterialiLookup"] = await _repository.GetMaterialiLookupAsync(cancellationToken: cancellationToken); return true; }
}

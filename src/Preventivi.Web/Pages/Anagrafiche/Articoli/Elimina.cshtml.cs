using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

public sealed class EliminaModel : PageModel
{
    private readonly IArticoloRepository _repository;
    private readonly ILogger<EliminaModel> _logger;
    public EliminaModel(IArticoloRepository repository, ILogger<EliminaModel> logger) { _repository = repository; _logger = logger; }
    public ArticoloDettaglio? Articolo { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ? Page() : NotFound();

    public async Task<IActionResult> OnPostAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        byte[] versione;
        try { versione = Convert.FromBase64String(versioneRigaBase64); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return Page(); }
        try
        {
            await _repository.EliminaAsync(new AnagraficaProduttivaDeleteModel { Id = id, VersioneRiga = versione }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Articolo eliminato correttamente.";
            return RedirectToPage("./Index");
        }
        catch (SqlException exception) when (ArticoliSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Eliminazione articolo {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, ArticoliSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Articolo = await _repository.GetDettaglioAsync(id, cancellationToken);
        return Articolo is not null;
    }
}

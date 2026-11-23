using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Fornitori;

public sealed class EliminaModel : PageModel
{
    private readonly IFornitoreRepository _repository;
    private readonly ILogger<EliminaModel> _logger;
    public EliminaModel(IFornitoreRepository repository, ILogger<EliminaModel> logger) { _repository = repository; _logger = logger; }
    public IReadOnlyList<FornitoreDipendenza> Dipendenze { get; private set; } = [];
    public FornitoreDettaglio? Fornitore { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ? Page() : NotFound();

    public async Task<IActionResult> OnPostAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        byte[] versione;
        try { versione = Convert.FromBase64String(versioneRigaBase64 ?? string.Empty); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return Page(); }
        if (versione.Length != 8)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non è valida. Riaprire la pagina.");
            return Page();
        }
        try
        {
            await _repository.EliminaAsync(id, versione, User.Identity?.Name ?? "Sistema", cancellationToken);
            TempData["MessaggioSuccesso"] = "Fornitore eliminato correttamente.";
            return RedirectToPage("./Index");
        }
        catch (SqlException exception) when (FornitoriSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Eliminazione fornitore {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, FornitoriSqlErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Fornitore = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Fornitore is null) return false;
        Dipendenze = await _repository.GetDipendenzeAsync(id, cancellationToken);
        return true;
    }
}

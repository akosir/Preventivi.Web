using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class EliminaModel(IOrdineFornitoreRepository repository, ILogger<EliminaModel> logger) : PageModel
{
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<OrdineFornitoreRiga> Righe { get; private set; } = [];
    public IReadOnlyList<OrdineFornitoreDipendenza> Dipendenze { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, string? versione, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id });
        var token = OrdiniFornitoriErrori.LeggiVersione(versione, ModelState);
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.EliminaAsync(id, token, User.Identity?.Name ?? "Sistema", cancellationToken);
            TempData["MessaggioSuccesso"] = "Ordine eliminato correttamente.";
            return RedirectToPage("./Index");
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Eliminazione ordine {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return false;
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        Dipendenze = await repository.GetDipendenzeAsync(id, cancellationToken: cancellationToken);
        return true;
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class StampaModel(IOrdineFornitoreRepository repository) : PageModel
{
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<OrdineFornitoreRiga> Righe { get; private set; } = [];
    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return NotFound();
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        return Page();
    }
}

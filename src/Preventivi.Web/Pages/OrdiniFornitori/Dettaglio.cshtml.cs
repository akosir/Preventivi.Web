using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class DettaglioModel(IOrdineFornitoreRepository repository, IAllegatoRepository allegati) : PageModel
{
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<OrdineFornitoreRiga> Righe { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return NotFound();
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        Allegati = new()
        {
            Allegati = await allegati.GetElencoAsync(AllegatoEntita.OrdiniFornitori, id, cancellationToken),
            ReturnUrl = Url.Page("./Dettaglio", new { id })
        };
        return Page();
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte;

public sealed class DettaglioModel : PageModel
{
    private readonly IArticoloRepository _articoli;
    private readonly IDistintaBaseRepository _distinte;
    public DettaglioModel(IArticoloRepository articoli, IDistintaBaseRepository distinte) { _articoli = articoli; _distinte = distinte; }

    public ArticoloDettaglio? Articolo { get; private set; }
    public DistintaRevisioneDettaglio? Revisione { get; private set; }
    public IReadOnlyList<DistintaRevisioneListItem> Revisioni { get; private set; } = [];
    public IReadOnlyList<DistintaNodoItem> Nodi { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(int idArticolo, int? idRevisione, CancellationToken cancellationToken)
    {
        if (idArticolo <= 0) return NotFound();
        Articolo = await _articoli.GetDettaglioAsync(idArticolo, cancellationToken);
        if (Articolo is null) return NotFound();
        Revisioni = await _distinte.GetRevisioniAsync(idArticolo, cancellationToken);
        var idSelezionato = Revisioni.FirstOrDefault(x => x.Modificabile)?.IdRevisioneDistinta;
        if (idSelezionato.HasValue)
        {
            Revisione = await _distinte.GetRevisioneAsync(idSelezionato.Value, cancellationToken);
            if (Revisione is null || Revisione.IdArticolo != idArticolo) return NotFound();
            Nodi = await _distinte.GetNodiAsync(Revisione.IdRevisioneDistinta, cancellationToken);
        }
        return Page();
    }
}

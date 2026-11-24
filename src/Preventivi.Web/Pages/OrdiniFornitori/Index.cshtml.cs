using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class IndexModel(IOrdineFornitoreRepository repository, IFornitoreRepository fornitori) : PageModel
{
    [BindProperty(SupportsGet = true)] public OrdineFornitoreFiltro Filtro { get; set; } = new();
    public IReadOnlyList<OrdineFornitoreDettaglio> Ordini { get; private set; } = [];
    public IReadOnlyList<FornitoreDettaglio> Fornitori { get; private set; } = [];

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Fornitori = await fornitori.GetElencoAsync(cancellationToken: cancellationToken);
        if (Filtro.Dal > Filtro.Al)
            ModelState.AddModelError(string.Empty, "La data iniziale deve precedere la data finale.");
        if (Filtro.Stato is not null && !OrdineFornitoreStati.Tutti.Contains(Filtro.Stato))
            ModelState.AddModelError(string.Empty, "Selezionare uno stato valido.");
        if (ModelState.IsValid)
            Ordini = await repository.GetElencoAsync(Filtro, cancellationToken);
    }
}

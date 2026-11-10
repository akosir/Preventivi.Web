using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte;

public sealed class IndexModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    public IndexModel(IDistintaBaseRepository repository) => _repository = repository;

    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    public IReadOnlyList<DistintaArticoloListItem> Articoli { get; private set; } = [];

    public async Task OnGetAsync(CancellationToken cancellationToken) =>
        Articoli = await _repository.GetArticoliAsync(Ricerca, cancellationToken);
}

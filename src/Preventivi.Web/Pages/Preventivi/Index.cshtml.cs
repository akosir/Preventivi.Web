using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class IndexModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public IReadOnlyList<PreventivoListItem> Preventivi { get; private set; }
        = Array.Empty<PreventivoListItem>();

    public IndexModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public async Task OnGetAsync(
        CancellationToken cancellationToken)
    {
        Preventivi =
            await _repository.GetElencoAsync(cancellationToken);
    }
}
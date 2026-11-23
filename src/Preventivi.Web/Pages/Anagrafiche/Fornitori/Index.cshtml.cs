using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;
namespace Preventivi.Web.Pages.Anagrafiche.Fornitori;

public sealed class IndexModel(IFornitoreRepository repository) : PageModel
{
    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet = true)] public string Stato { get; set; } = "attivi";
    public IReadOnlyList<FornitoreDettaglio> Fornitori { get; private set; } = [];
    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        bool? soloAttivi = Stato switch { "attivi" => true, "nonattivi" => false, _ => null };
        Fornitori = await repository.GetElencoAsync(Ricerca, soloAttivi, cancellationToken);
    }
}

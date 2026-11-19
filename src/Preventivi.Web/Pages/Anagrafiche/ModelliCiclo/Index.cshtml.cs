using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo;

public sealed class IndexModel(IModelloCicloRepository repository) : PageModel
{
    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet = true)] public string Stato { get; set; } = "attivi";
    public IReadOnlyList<ModelloCicloListItem> Modelli { get; private set; } = [];

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        bool? soloAttivi = Stato switch { "attivi" => true, "nonattivi" => false, _ => null };
        Modelli = await repository.GetElencoAsync(Ricerca, soloAttivi, cancellationToken);
    }
}

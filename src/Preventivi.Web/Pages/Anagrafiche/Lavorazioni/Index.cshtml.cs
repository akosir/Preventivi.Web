using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Lavorazioni;

public sealed class IndexModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    public IndexModel(IAnagraficheProduttiveRepository repository) { _repository = repository; }
    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet = true)] public string Stato { get; set; } = "attive";
    [BindProperty(SupportsGet = true)] public string? InternaEsterna { get; set; }
    public IReadOnlyList<LavorazioneListItem> Lavorazioni { get; private set; } = [];
    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        bool? soloAttive = Stato switch { "attive" => true, "nonattive" => false, _ => null };
        Lavorazioni = await _repository.GetLavorazioniAsync(Ricerca, soloAttive, InternaEsterna, cancellationToken);
    }
}

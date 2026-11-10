using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

public sealed class IndexModel : PageModel
{
    private readonly IArticoloRepository _repository;

    public IndexModel(IArticoloRepository repository)
    {
        _repository = repository;
    }

    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet = true)] public string Stato { get; set; } = "attivi";
    [BindProperty(SupportsGet = true)] public int? IdCliente { get; set; }
    public IReadOnlyList<ClienteAnagraficaLookupItem> Clienti { get; private set; } = [];
    public IReadOnlyList<ArticoloListItem> Articoli { get; private set; } = [];

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        bool? soloAttivi = Stato switch
        {
            "attivi" => true,
            "nonattivi" => false,
            _ => null
        };

        Clienti = await _repository.GetClientiAsync(cancellationToken: cancellationToken);
        Articoli = await _repository.GetElencoAsync(Ricerca, soloAttivi, IdCliente, cancellationToken);
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Campionature;
using Preventivi.Core.Clienti;

namespace Preventivi.Web.Pages.Campionature;

public class IndexModel : PageModel
{
    private readonly ICampionaturaRepository _campionaturaRepository;
    private readonly IClienteRepository _clienteRepository;

    public IndexModel(
        ICampionaturaRepository campionaturaRepository,
        IClienteRepository clienteRepository)
    {
        _campionaturaRepository = campionaturaRepository;
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdCliente { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdRichiestaCliente { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Stato { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Priorita { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? ConsegnaDa { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? ConsegnaA { get; set; }

    public IReadOnlyList<CampionaturaListItem> Campionature { get; private set; }
        = Array.Empty<CampionaturaListItem>();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public IReadOnlyList<CampionaturaRichiestaLookupItem> Richieste { get; private set; }
        = Array.Empty<CampionaturaRichiestaLookupItem>();

    public IReadOnlyList<string> Stati => CampionaturaValori.Stati;
    public IReadOnlyList<string> PrioritaDisponibili => CampionaturaValori.Priorita;

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Campionature = await _campionaturaRepository.GetElencoAsync(
            new CampionaturaFiltro
            {
                Ricerca = Pulisci(Ricerca),
                IdCliente = IdCliente,
                IdRichiestaCliente = IdRichiestaCliente,
                Stato = Pulisci(Stato),
                Priorita = Pulisci(Priorita),
                ConsegnaDa = ConsegnaDa,
                ConsegnaA = ConsegnaA
            },
            cancellationToken);

        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);
        Richieste = await _campionaturaRepository.GetRichiesteAsync(cancellationToken);
    }

    private static string? Pulisci(string? valore) =>
        string.IsNullOrWhiteSpace(valore) ? null : valore.Trim();
}

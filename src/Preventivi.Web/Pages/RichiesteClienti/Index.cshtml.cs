using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Core.RichiesteClienti;

namespace Preventivi.Web.Pages.RichiesteClienti;

public class IndexModel : PageModel
{
    private readonly IRichiestaClienteRepository _richiestaRepository;
    private readonly IClienteRepository _clienteRepository;

    public IndexModel(
        IRichiestaClienteRepository richiestaRepository,
        IClienteRepository clienteRepository)
    {
        _richiestaRepository = richiestaRepository;
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdCliente { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Stato { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Priorita { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? InteresseCliente { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? ScadenzaDa { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? ScadenzaA { get; set; }

    public IReadOnlyList<RichiestaClienteListItem> Richieste { get; private set; }
        = Array.Empty<RichiestaClienteListItem>();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public IReadOnlyList<string> Stati => RichiestaClienteValori.Stati;
    public IReadOnlyList<string> PrioritaDisponibili => RichiestaClienteValori.Priorita;
    public IReadOnlyList<string> Interessi => RichiestaClienteValori.Interessi;

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Richieste = await _richiestaRepository.GetElencoAsync(
            new RichiestaClienteFiltro
            {
                Ricerca = Pulisci(Ricerca),
                IdCliente = IdCliente,
                Stato = Pulisci(Stato),
                Priorita = Pulisci(Priorita),
                InteresseCliente = Pulisci(InteresseCliente),
                ScadenzaDa = ScadenzaDa,
                ScadenzaA = ScadenzaA
            },
            cancellationToken);

        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);
    }

    private static string? Pulisci(string? valore) =>
        string.IsNullOrWhiteSpace(valore) ? null : valore.Trim();
}

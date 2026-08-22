using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Web.Mappers.Clienti;
using Preventivi.Web.UI.Common.DataGrid;
using Preventivi.Web.UI.Modules.Clienti;


namespace Preventivi.Web.Pages.Clienti;

public class IndexModel : PageModel
{
    private readonly IClienteRepository _clienteRepository;

    public IndexModel(
        IClienteRepository clienteRepository)
    {
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public string Stato { get; set; } = "attivi";

    public DataGridModel Griglia { get; private set; } = new();

    public ClientiHeaderModel Header { get; private set; } = new();

    public ClientiSearchBarModel BarraRicerca { get; private set; } = new();

    public async Task OnGetAsync(
        CancellationToken cancellationToken)
    {
        bool? soloAttivi = Stato switch
        {
            "attivi" => true,
            "nonattivi" => false,
            _ => null
        };

        var clienti =
            await _clienteRepository.GetElencoAsync(
                Ricerca,
                soloAttivi,
                cancellationToken);

        Griglia =
            ClienteGridMapper.ToGrid(clienti);

        Header = new ClientiHeaderModel
        {
            Titolo = "Clienti",

            Sottotitolo = "Gestione anagrafica clienti",

            TestoPulsanteNuovo = "Nuovo Cliente",

            UrlNuovo = "/Clienti/Nuovo"
        };

        BarraRicerca = new ClientiSearchBarModel
        {
            Ricerca = Ricerca,
            Stato = Stato
        };
    }
}
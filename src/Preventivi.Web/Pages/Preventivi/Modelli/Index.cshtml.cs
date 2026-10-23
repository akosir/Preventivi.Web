using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli;

public sealed class IndexModel : PageModel
{
    private readonly IModelloPreventivoRepository _repository;
    private readonly IClienteRepository _clienteRepository;

    public IndexModel(
        IModelloPreventivoRepository repository,
        IClienteRepository clienteRepository)
    {
        _repository = repository;
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdCliente { get; set; }

    [BindProperty(SupportsGet = true)]
    public string Stato { get; set; } = "attivi";

    public IReadOnlyList<ModelloPreventivoListItem> Modelli { get; private set; }
        = Array.Empty<ModelloPreventivoListItem>();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        var soloAttivi = Stato switch
        {
            "attivi" => true,
            "nonattivi" => false,
            _ => (bool?)null
        };

        Modelli = await _repository.GetElencoAsync(
            Ricerca,
            IdCliente,
            soloAttivi,
            cancellationToken);
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);
    }
}

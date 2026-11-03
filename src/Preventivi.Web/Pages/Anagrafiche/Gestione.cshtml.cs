using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class GestioneModel : PageModel
{
    private readonly IAnagraficheBaseRepository _repository;

    public GestioneModel(IAnagraficheBaseRepository repository)
    {
        _repository = repository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public string Stato { get; set; } = "attivi";

    public AnagraficaBasePagina? Pagina { get; private set; }
    public IReadOnlyList<AnagraficaBaseListItem> Elementi { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(string tipo, CancellationToken cancellationToken)
    {
        if (!AnagraficaBasePagina.TryGet(tipo, out var pagina))
        {
            return NotFound();
        }

        Pagina = pagina;
        bool? soloAttivi = Stato switch
        {
            "attivi" => true,
            "nonattivi" => false,
            _ => null
        };

        Elementi = await _repository.GetElencoAsync(
            pagina.Tipo,
            Ricerca,
            soloAttivi,
            cancellationToken);
        return Page();
    }
}

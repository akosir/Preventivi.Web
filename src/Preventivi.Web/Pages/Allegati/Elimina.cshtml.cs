using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;


namespace Preventivi.Web.Pages.Allegati;

public class EliminaModel : PageModel
{

    private readonly IAllegatoApplicationService _applicationService;
    private readonly IAllegatoRepository _allegatoRepository;

    public EliminaModel(
    IAllegatoApplicationService applicationService,
    IAllegatoRepository allegatoRepository)
    {
        _applicationService = applicationService;
        _allegatoRepository = allegatoRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdAllegato { get; set; }

    public string NomeFileOriginale { get; private set; } = "";

    public async Task<IActionResult> OnGetAsync(
        CancellationToken cancellationToken)
    {
        if (IdAllegato <= 0)
        {
            return BadRequest();
        }

        var allegato =
            await _allegatoRepository.GetByIdAsync(
                IdAllegato,
                cancellationToken);

        if (allegato is null)
        {
            return NotFound();
        }

        NomeFileOriginale =
            allegato.NomeFileOriginale;

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        CancellationToken cancellationToken)
    {
        var allegato =
            await _allegatoRepository.GetByIdAsync(
                IdAllegato,
                cancellationToken);

        if (allegato is null)
        {
            return NotFound();
        }

        await _applicationService.EliminaAsync(
    IdAllegato,
    cancellationToken);

        TempData["MessaggioSuccesso"] =
            "Allegato eliminato definitivamente.";

        if (allegato.Entita == "Clienti")
        {
            return RedirectToPage(
                "/Clienti/Dettaglio",
                new
                {
                    IdCliente = allegato.IdEntita
                });
        }

        return RedirectToPage("/Index");
    }
}
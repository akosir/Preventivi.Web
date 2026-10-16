using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Web.Sicurezza;


namespace Preventivi.Web.Pages.Allegati;

public class EliminaModel : PageModel
{

    private readonly IAllegatoApplicationService _applicationService;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<EliminaModel> _logger;

    public EliminaModel(
        IAllegatoApplicationService applicationService,
        IAllegatoRepository allegatoRepository,
        ILogger<EliminaModel> logger)
    {
        _applicationService = applicationService;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    [BindProperty(SupportsGet = true)]
    public int IdAllegato { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? ReturnUrl { get; set; }

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

        if (!AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(
            User,
            allegato.Entita))
        {
            return Forbid();
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

        if (!AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(
            User,
            allegato.Entita))
        {
            return Forbid();
        }

        try
        {
            await _applicationService.EliminaAsync(
                IdAllegato,
                cancellationToken);
        }
        catch (AllegatoStorageException exception)
        {
            _logger.LogError(
                exception,
                "Errore storage durante l'eliminazione dell'allegato {IdAllegato}.",
                IdAllegato);

            NomeFileOriginale = allegato.NomeFileOriginale;
            ModelState.AddModelError(
                string.Empty,
                "Non è stato possibile eliminare l'allegato. Verificare la configurazione dello storage.");

            return Page();
        }

        TempData["MessaggioSuccesso"] =
            "Allegato eliminato definitivamente.";

        if (allegato.Entita == AllegatoEntita.Clienti)
        {
            return RedirectToPage(
                "/Clienti/Dettaglio",
                new
                {
                    IdCliente = allegato.IdEntita
                });
        }

        if (allegato.Entita == AllegatoEntita.Preventivi)
        {
            return RedirectToPage(
                "/Preventivi/Dettaglio",
                new
                {
                    id = allegato.IdEntita
                });
        }

        if (IsLocalReturnUrl(ReturnUrl))
        {
            return LocalRedirect(ReturnUrl!);
        }

        return RedirectToPage("/Index");
    }

    private static bool IsLocalReturnUrl(string? returnUrl)
    {
        return !string.IsNullOrWhiteSpace(returnUrl) &&
            returnUrl.StartsWith("/", StringComparison.Ordinal) &&
            !returnUrl.StartsWith("//", StringComparison.Ordinal);
    }
}

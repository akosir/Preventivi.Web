using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.StaticFiles;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Data.Allegati;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages.Allegati;

public class ApriModel : PageModel
{
    private readonly IAllegatoApplicationService _applicationService;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<ApriModel> _logger;

    public string? MessaggioErrore { get; private set; }

    public ApriModel(
        IAllegatoApplicationService applicationService,
        IAllegatoRepository allegatoRepository,
        ILogger<ApriModel> logger)
    {
        _applicationService = applicationService;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public async Task<IActionResult> OnGetAsync(
      int IdAllegato,
      CancellationToken cancellationToken)
    {
        if (IdAllegato <= 0)
        {
            return BadRequest();
        }

        var allegato = await _allegatoRepository.GetByIdAsync(
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

        StorageFileResult file;

        try
        {
            file =
                await _applicationService.ApriAsync(
                    IdAllegato,
                    cancellationToken);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (FileNotFoundException)
        {
            MessaggioErrore =
                "Il file allegato non è disponibile nello storage.";

            return Page();
        }
        catch (AllegatoStorageException exception)
        {
            _logger.LogError(
                exception,
                "Errore storage durante l'apertura dell'allegato {IdAllegato}.",
                IdAllegato);

            MessaggioErrore =
                "Non è stato possibile aprire l'allegato. Verificare la configurazione dello storage.";

            return Page();
        }

        var provider =
            new FileExtensionContentTypeProvider();

        if (!provider.TryGetContentType(
                file.NomeFileOriginale,
                out var contentType))
        {
            contentType = "application/octet-stream";
        }

        return File(
            file.Stream,
            contentType);
    }
}

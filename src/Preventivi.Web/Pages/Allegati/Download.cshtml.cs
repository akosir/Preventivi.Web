using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.StaticFiles;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.Allegati;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages.Allegati;

public class DownloadModel : PageModel
{
    private readonly IAllegatoApplicationService _applicationService;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<DownloadModel> _logger;

    public DownloadModel(
        IAllegatoApplicationService applicationService,
        IAllegatoRepository allegatoRepository,
        ILogger<DownloadModel> logger)
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
            TempData["MessaggioErrore"] =
                "Il file allegato non è presente nello storage.";

            return RedirectToPage("/Index");
        }
        catch (AllegatoStorageException exception)
        {
            _logger.LogError(
                exception,
                "Errore storage durante il download dell'allegato {IdAllegato}.",
                IdAllegato);

            TempData["MessaggioErrore"] =
                "Non è stato possibile scaricare l'allegato. Verificare la configurazione dello storage.";

            return RedirectToPage("/Index");
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
            contentType,
            file.NomeFileOriginale);
    }
}

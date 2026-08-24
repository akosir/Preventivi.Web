using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.StaticFiles;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Web.Pages.Allegati;

public class DownloadModel : PageModel
{
    private readonly IAllegatoApplicationService _applicationService;

    public DownloadModel(
        IAllegatoApplicationService applicationService)
    {
        _applicationService = applicationService;
    }

    public async Task<IActionResult> OnGetAsync(
        int IdAllegato,
        CancellationToken cancellationToken)
    {
        if (IdAllegato <= 0)
        {
            return BadRequest();
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

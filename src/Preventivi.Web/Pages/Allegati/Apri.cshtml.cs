using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.StaticFiles;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Data.Allegati;

namespace Preventivi.Web.Pages.Allegati;

public class ApriModel : PageModel
{

    private readonly IAllegatoApplicationService _applicationService;

    public string? MessaggioErrore { get; private set; }

    public ApriModel(
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
            MessaggioErrore =
                "Il file allegato non è disponibile nello storage.";

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
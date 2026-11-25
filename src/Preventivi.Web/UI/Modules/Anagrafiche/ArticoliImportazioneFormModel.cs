using Microsoft.AspNetCore.Http;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class ArticoliImportazioneFormModel
{
    public IFormFile? File { get; set; }
    public string ContenutoBase64 { get; set; } = string.Empty;
    public string TokenAnteprima { get; set; } = string.Empty;
}

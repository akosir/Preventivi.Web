using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class DistintaImportazioneFormModel
{
    public IFormFile? File { get; set; }

    [Required]
    public string ContenutoBase64 { get; set; } = string.Empty;

    [Required]
    [StringLength(260)]
    public string NomeFile { get; set; } = string.Empty;

    [Required]
    [StringLength(64, MinimumLength = 64)]
    public string ImprontaSha256 { get; set; } = string.Empty;

    [Required]
    public string VersioneRigaBase64 { get; set; } = string.Empty;
}

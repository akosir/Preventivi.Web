using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class AnagraficaBaseFormModel
{
    [StringLength(10, ErrorMessage = "Il codice puo contenere al massimo 10 caratteri.")]
    public string? Codice { get; set; }

    [Required(ErrorMessage = "La descrizione e obbligatoria.")]
    [StringLength(100, ErrorMessage = "La descrizione puo contenere al massimo 100 caratteri.")]
    public string Descrizione { get; set; } = string.Empty;

    public string? VersioneRigaBase64 { get; set; }
}

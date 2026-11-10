using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class ArticoloFormModel
{
    [Required(ErrorMessage = "Il codice articolo e obbligatorio.")]
    [StringLength(50, ErrorMessage = "Il codice puo contenere al massimo 50 caratteri.")]
    public string CodiceArticolo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione e obbligatoria.")]
    [StringLength(200, ErrorMessage = "La descrizione puo contenere al massimo 200 caratteri.")]
    public string Descrizione { get; set; } = string.Empty;

    [StringLength(20, ErrorMessage = "La versione puo contenere al massimo 20 caratteri.")]
    public string? Versione { get; set; }

    public int? IdCliente { get; set; }
    public string? NoteTecniche { get; set; }
    public string? VersioneRigaBase64 { get; set; }
}

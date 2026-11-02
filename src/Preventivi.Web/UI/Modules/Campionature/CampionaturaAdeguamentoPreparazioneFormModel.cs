using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Campionature;

public sealed class CampionaturaAdeguamentoPreparazioneFormModel
{
    [Required(ErrorMessage = "Inserire il codice della variante.")]
    [StringLength(30, ErrorMessage = "Il codice della variante non puo superare 30 caratteri.")]
    public string CodiceVariante { get; set; } = string.Empty;

    [Required(ErrorMessage = "Inserire la descrizione della variante.")]
    [StringLength(250, ErrorMessage = "La descrizione della variante non puo superare 250 caratteri.")]
    public string DescrizioneVariante { get; set; } = string.Empty;
}

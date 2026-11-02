using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Campionature;

public sealed class CampionaturaAdeguamentoFormModel
{
    [Required(ErrorMessage = "Inserire la descrizione dell'adeguamento.")]
    [Display(Name = "Descrizione adeguamento")]
    public string DescrizioneAdeguamento { get; set; } = string.Empty;

    [Display(Name = "Impatto stimato sui costi")]
    public decimal ImpattoCostoStimato { get; set; }

    [Display(Name = "Impatto stimato sulla vendita")]
    public decimal ImpattoVenditaStimato { get; set; }

    [Display(Name = "Note")]
    public string? Note { get; set; }

    public string VersioneRigaBase64 { get; set; } = string.Empty;
    public string VersioneRilievoBase64 { get; set; } = string.Empty;
}

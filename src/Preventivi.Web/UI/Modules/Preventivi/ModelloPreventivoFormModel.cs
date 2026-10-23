using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Preventivi;

public sealed class ModelloPreventivoFormModel
{
    [Required(ErrorMessage = "Inserire il codice del modello.")]
    [StringLength(50)]
    [Display(Name = "Codice modello")]
    public string CodiceModelloPreventivo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Inserire la descrizione del modello.")]
    [StringLength(150)]
    [Display(Name = "Descrizione")]
    public string Descrizione { get; set; } = string.Empty;

    [Display(Name = "Cliente associato")]
    public int? IdCliente { get; set; }

    [StringLength(250)]
    [Display(Name = "Oggetto proposto")]
    public string? Oggetto { get; set; }

    [Display(Name = "Note proposte")]
    public string? Note { get; set; }
}

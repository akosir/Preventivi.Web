using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Preventivi;

public sealed class ModelloPreventivoRigaFormModel
{
    [Range(1, int.MaxValue, ErrorMessage = "Il numero riga deve essere maggiore di zero.")]
    [Display(Name = "Numero riga")]
    public int RigaNr { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Selezionare il tipo riga.")]
    [Display(Name = "Tipo riga")]
    public int IdTipoRiga { get; set; }

    [Display(Name = "Articolo")]
    public int? IdArticolo { get; set; }

    [Display(Name = "Modello ciclo")]
    public int? IdModelloCiclo { get; set; }

    [Required(ErrorMessage = "Inserire la descrizione della riga.")]
    [StringLength(250)]
    [Display(Name = "Descrizione")]
    public string DescrizioneVoce { get; set; } = string.Empty;

    [Range(0.0001, 99999999999999d, ErrorMessage = "La quantita deve essere maggiore di zero.")]
    [Display(Name = "Quantita")]
    public decimal Quantita { get; set; } = 1;

    [Range(0d, 99999999999999d, ErrorMessage = "Il prezzo unitario non puo essere negativo.")]
    [Display(Name = "Prezzo unitario vendita")]
    public decimal PrezzoUnitarioVendita { get; set; }

    [Display(Name = "Note")]
    public string? Note { get; set; }
}

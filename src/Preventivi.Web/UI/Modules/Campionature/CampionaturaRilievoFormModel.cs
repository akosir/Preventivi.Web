using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Campionature;

public sealed class CampionaturaRilievoFormModel
{
    [Required(ErrorMessage = "Inserire la data del rilievo.")]
    [Display(Name = "Data rilievo")]
    [DataType(DataType.Date)]
    public DateOnly? DataRilevazione { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Selezionare il tipo di problematica.")]
    [Display(Name = "Tipo problematica")]
    public int IdTipoProblematica { get; set; }

    [Display(Name = "Problematica standard")]
    public int? IdProblematicaStandard { get; set; }

    [Required(ErrorMessage = "Inserire la descrizione del problema.")]
    [Display(Name = "Descrizione problema")]
    public string DescrizioneProblema { get; set; } = string.Empty;

    [Required(ErrorMessage = "Selezionare la gravita.")]
    [Display(Name = "Gravita")]
    public string Gravita { get; set; } = "Media";

    [Display(Name = "Causa presunta")]
    public string? CausaPresunta { get; set; }

    [Display(Name = "Soluzione proposta")]
    public string? SoluzioneProposta { get; set; }

    [Display(Name = "Richiede un nuovo campione")]
    public bool RichiedeNuovoCampione { get; set; }

    [Display(Name = "Note per il cliente")]
    public string? NoteCliente { get; set; }

    [Display(Name = "Note interne")]
    public string? NoteInterne { get; set; }

    public string VersioneRigaBase64 { get; set; } = string.Empty;
}

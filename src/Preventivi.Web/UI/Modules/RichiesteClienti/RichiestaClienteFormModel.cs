using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.RichiesteClienti;

public sealed class RichiestaClienteFormModel
{
    [Required(ErrorMessage = "Inserire la data della richiesta.")]
    [CustomValidation(typeof(RichiestaClienteFormModel), nameof(ValidaDataRichiesta))]
    [Display(Name = "Data richiesta")]
    [DataType(DataType.Date)]
    public DateOnly DataRichiesta { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Selezionare un cliente.")]
    [Display(Name = "Cliente")]
    public int IdCliente { get; set; }

    [Required(ErrorMessage = "Inserire l'oggetto della richiesta.")]
    [StringLength(250, ErrorMessage = "L'oggetto non puo superare 250 caratteri.")]
    [Display(Name = "Oggetto")]
    public string Oggetto { get; set; } = string.Empty;

    [Display(Name = "Descrizione richiesta")]
    public string? DescrizioneRichiesta { get; set; }

    [Required(ErrorMessage = "Selezionare lo stato.")]
    [StringLength(30)]
    [Display(Name = "Stato")]
    public string Stato { get; set; } = "Nuova";

    [Required(ErrorMessage = "Selezionare la priorita.")]
    [StringLength(20)]
    [Display(Name = "Priorita")]
    public string Priorita { get; set; } = "Media";

    [StringLength(20)]
    [Display(Name = "Interesse cliente")]
    public string? InteresseCliente { get; set; }

    [Display(Name = "Data scadenza")]
    [DataType(DataType.Date)]
    public DateOnly? DataScadenza { get; set; }

    [Range(0, 100, ErrorMessage = "La probabilita deve essere compresa tra 0 e 100.")]
    [Display(Name = "Probabilita di chiusura %")]
    public int? ProbabilitaChiusura { get; set; }

    [Display(Name = "Note")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }

    public static ValidationResult? ValidaDataRichiesta(
        DateOnly dataRichiesta,
        ValidationContext validationContext)
    {
        return dataRichiesta == default
            ? new ValidationResult(
                "Inserire la data della richiesta.",
                [nameof(DataRichiesta)])
            : ValidationResult.Success;
    }
}

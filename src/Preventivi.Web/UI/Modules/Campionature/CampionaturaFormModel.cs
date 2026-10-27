using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Campionature;

public sealed class CampionaturaFormModel
{
    [Required(ErrorMessage = "Inserire la data della campionatura.")]
    [Display(Name = "Data campionatura")]
    [DataType(DataType.Date)]
    public DateOnly? DataCampionatura { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Selezionare una richiesta cliente.")]
    [Display(Name = "Richiesta cliente")]
    public int IdRichiestaCliente { get; set; }

    [Display(Name = "Preventivo collegato")]
    public int? IdPreventivo { get; set; }

    [Display(Name = "Variante collegata")]
    public int? IdVariantePreventivo { get; set; }

    [Required(ErrorMessage = "Inserire l'oggetto della campionatura.")]
    [StringLength(250, ErrorMessage = "L'oggetto non puo superare 250 caratteri.")]
    [Display(Name = "Oggetto")]
    public string Oggetto { get; set; } = string.Empty;

    [Display(Name = "Descrizione campione")]
    public string? DescrizioneCampione { get; set; }

    [Required(ErrorMessage = "Selezionare lo stato.")]
    [Display(Name = "Stato")]
    public string Stato { get; set; } = "Aperta";

    [Required(ErrorMessage = "Selezionare la priorita.")]
    [Display(Name = "Priorita")]
    public string Priorita { get; set; } = "Media";

    [Display(Name = "Data richiesta campione")]
    [DataType(DataType.Date)]
    public DateOnly? DataRichiestaCampione { get; set; }

    [Display(Name = "Consegna prevista")]
    [DataType(DataType.Date)]
    public DateOnly? DataPrevistaConsegna { get; set; }

    [Display(Name = "Consegna effettiva")]
    [DataType(DataType.Date)]
    public DateOnly? DataConsegnaCampione { get; set; }

    [Display(Name = "Data chiusura")]
    [DataType(DataType.Date)]
    public DateOnly? DataChiusura { get; set; }

    [Display(Name = "Esito")]
    public string? Esito { get; set; }

    [Display(Name = "Note")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }
}

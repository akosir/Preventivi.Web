using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.OrdiniFornitori;

public sealed class OrdineFornitoreFormModel
{
    [Required(ErrorMessage = "La data ordine è obbligatoria.")]
    [DataType(DataType.Date)]
    public DateTime? DataOrdine { get; set; }
    [Required(ErrorMessage = "Selezionare un fornitore.")]
    [Range(1, int.MaxValue)]
    public int? IdFornitore { get; set; }
    [StringLength(250)]
    public string? Oggetto { get; set; }
    public string? Note { get; set; }
    [DataType(DataType.Date)]
    public DateTime? DataConsegnaPrevista { get; set; }
    public string? VersioneRiga { get; set; }
}

public sealed class OrdineFornitoreRigaFormModel
{
    [Range(1, int.MaxValue, ErrorMessage = "Inserire un numero riga positivo.")]
    public int RigaNr { get; set; } = 1;
    [Required]
    [RegularExpression("^(Materiale|Lavorazione|Nota)$", ErrorMessage = "Selezionare un tipo riga valido.")]
    public string TipoRiga { get; set; } = "Materiale";
    public int? IdMateriale { get; set; }
    public int? IdLavorazione { get; set; }
    [Required(ErrorMessage = "La descrizione è obbligatoria.")]
    [StringLength(250)]
    public string Descrizione { get; set; } = string.Empty;
    [StringLength(10)]
    public string? UM { get; set; }
    [Range(typeof(decimal), "0.0001", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "La quantità deve essere positiva.")]
    public decimal Quantita { get; set; } = 1;
    [Range(typeof(decimal), "0", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il prezzo non può essere negativo.")]
    public decimal PrezzoUnitario { get; set; }
    [DataType(DataType.Date)]
    public DateTime? DataConsegnaPrevista { get; set; }
    [StringLength(500)]
    public string? Note { get; set; }
    public string? VersioneRiga { get; set; }
    public string? VersioneOrdine { get; set; }
}

using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class DistintaNodoFormModel
{
    [Required(ErrorMessage = "Selezionare il tipo di nodo.")]
    [Range(1, int.MaxValue, ErrorMessage = "Selezionare il tipo di nodo.")]
    public int? IdTipoNodo { get; set; }

    [StringLength(50, ErrorMessage = "Il codice nodo puo contenere al massimo 50 caratteri.")]
    public string? CodiceNodo { get; set; }

    [Required(ErrorMessage = "La descrizione del nodo e obbligatoria.")]
    [StringLength(200, ErrorMessage = "La descrizione puo contenere al massimo 200 caratteri.")]
    public string DescrizioneNodo { get; set; } = string.Empty;

    [Range(typeof(decimal), "0.0001", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "La quantita base deve essere maggiore di zero.")]
    public decimal QuantitaBase { get; set; } = 1m;

    [Range(0, int.MaxValue, ErrorMessage = "L'ordine non puo essere negativo.")]
    public int OrdineVisualizzazione { get; set; }

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }

    public int? IdNodoPadre { get; set; }
    public string? VersioneRigaBase64 { get; set; }
}

public sealed class DistintaMaterialeFormModel
{
    [Required(ErrorMessage = "Selezionare il materiale.")]
    [Range(1, int.MaxValue, ErrorMessage = "Selezionare il materiale.")]
    public int? IdMateriale { get; set; }

    [Range(typeof(decimal), "0.0001", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "La quantita deve essere maggiore di zero.")]
    public decimal Quantita { get; set; } = 1m;

    [Range(typeof(decimal), "0", "9999999.99", ParseLimitsInInvariantCulture = true, ErrorMessage = "Lo scarto non puo essere negativo.")]
    public decimal CoeffScartoPerc { get; set; }

    [Range(typeof(decimal), "0", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il costo unitario non puo essere negativo.")]
    public decimal CostoUnitario { get; set; }

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }
}

public sealed class DistintaLavorazioneFormModel
{
    [Required(ErrorMessage = "Selezionare la lavorazione.")]
    [Range(1, int.MaxValue, ErrorMessage = "Selezionare la lavorazione.")]
    public int? IdLavorazione { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "La sequenza deve essere maggiore di zero.")]
    public int Sequenza { get; set; } = 1;

    [Range(typeof(decimal), "0", "9999999999999999.99", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il tempo di setup non puo essere negativo.")]
    public decimal TempoSetupMin { get; set; }

    [Range(typeof(decimal), "0", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il tempo per pezzo non puo essere negativo.")]
    public decimal TempoPezzoMin { get; set; }

    [Range(typeof(decimal), "0", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il costo orario non puo essere negativo.")]
    public decimal CostoOrario { get; set; }

    [Range(typeof(decimal), "0", "99999999999999.9999", ParseLimitsInInvariantCulture = true, ErrorMessage = "Il costo fisso non puo essere negativo.")]
    public decimal CostoFisso { get; set; }

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }
}

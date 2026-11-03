using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class LavorazioneFormModel
{
    [Required(ErrorMessage = "Il codice lavorazione e obbligatorio.")]
    [StringLength(50, ErrorMessage = "Il codice puo contenere al massimo 50 caratteri.")]
    public string CodiceLavorazione { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione e obbligatoria.")]
    [StringLength(150, ErrorMessage = "La descrizione puo contenere al massimo 150 caratteri.")]
    public string Descrizione { get; set; } = string.Empty;

    [Required(ErrorMessage = "La tipologia e obbligatoria.")]
    public string InternaEsterna { get; set; } = string.Empty;

    [Range(
        typeof(decimal),
        "0",
        "99999999999999.9999",
        ErrorMessage = "Il costo orario non puo essere negativo.",
        ParseLimitsInInvariantCulture = true,
        ConvertValueInInvariantCulture = true)]
    public decimal CostoOrarioStandard { get; set; }

    [Range(
        typeof(decimal),
        "0",
        "9999999999999999.99",
        ErrorMessage = "Il tempo di setup non puo essere negativo.",
        ParseLimitsInInvariantCulture = true,
        ConvertValueInInvariantCulture = true)]
    public decimal TempoSetupMinDefault { get; set; }

    [Range(
        typeof(decimal),
        "0",
        "99999999999999.9999",
        ErrorMessage = "Il tempo per pezzo non puo essere negativo.",
        ParseLimitsInInvariantCulture = true,
        ConvertValueInInvariantCulture = true)]
    public decimal TempoPezzoMinDefault { get; set; }

    public bool AcquistabileEsterna { get; set; }
    public int? IdFornitorePredefinito { get; set; }

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }
}

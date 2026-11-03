using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class MaterialeFormModel
{
    [Required(ErrorMessage = "Il codice materiale e obbligatorio.")]
    [StringLength(50, ErrorMessage = "Il codice puo contenere al massimo 50 caratteri.")]
    public string CodiceMateriale { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione e obbligatoria.")]
    [StringLength(200, ErrorMessage = "La descrizione puo contenere al massimo 200 caratteri.")]
    public string Descrizione { get; set; } = string.Empty;

    [Required(ErrorMessage = "Selezionare un'unita di misura.")]
    [Range(1, int.MaxValue, ErrorMessage = "Selezionare un'unita di misura.")]
    public int? IdUM { get; set; }

    [Required(ErrorMessage = "Il tipo materiale e obbligatorio.")]
    public string TipoMateriale { get; set; } = string.Empty;

    [Range(
        typeof(decimal),
        "0",
        "99999999999999.9999",
        ErrorMessage = "Il costo unitario non puo essere negativo.",
        ParseLimitsInInvariantCulture = true,
        ConvertValueInInvariantCulture = true)]
    public decimal CostoUnitario { get; set; }

    public bool GestitoAAcquisto { get; set; }
    public int? IdFornitorePredefinito { get; set; }

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }

    public string? VersioneRigaBase64 { get; set; }
}

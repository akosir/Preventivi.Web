using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class ModelloCicloFormModel
{
    [Required(ErrorMessage = "Il codice modello ciclo e obbligatorio.")]
    [StringLength(50, ErrorMessage = "Il codice puo contenere al massimo 50 caratteri.")]
    public string CodiceModelloCiclo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La descrizione e obbligatoria.")]
    [StringLength(150, ErrorMessage = "La descrizione puo contenere al massimo 150 caratteri.")]
    public string Descrizione { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Le note possono contenere al massimo 500 caratteri.")]
    public string? Note { get; set; }
    public string? VersioneRigaBase64 { get; set; }
}

public sealed class ModelloCicloRigaFormModel
{
    [Range(1, int.MaxValue, ErrorMessage = "Il numero riga deve essere maggiore di zero.")]
    public int RigaNr { get; set; } = 1;

    [Range(1, int.MaxValue, ErrorMessage = "La sequenza deve essere maggiore di zero.")]
    public int Sequenza { get; set; } = 10;

    [Range(1, int.MaxValue, ErrorMessage = "Selezionare una lavorazione.")]
    public int IdLavorazione { get; set; }

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

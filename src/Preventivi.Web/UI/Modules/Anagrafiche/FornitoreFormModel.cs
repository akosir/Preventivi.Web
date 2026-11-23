using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed class FornitoreFormModel
{
    [Required(ErrorMessage = "Il campo codice fornitore è obbligatorio.")]
    [StringLength(30, ErrorMessage = "Sono consentiti al massimo 30 caratteri.")]
    public string CodiceFornitore { get; set; } = string.Empty;

    [Required(ErrorMessage = "Il campo ragione sociale è obbligatorio.")]
    [StringLength(150, ErrorMessage = "Sono consentiti al massimo 150 caratteri.")]
    public string RagioneSociale { get; set; } = string.Empty;

    [StringLength(20, ErrorMessage = "Sono consentiti al massimo 20 caratteri.")]
    public string? PartitaIVA { get; set; }

    [StringLength(20, ErrorMessage = "Sono consentiti al massimo 20 caratteri.")]
    public string? CodiceFiscale { get; set; }

    [StringLength(150, ErrorMessage = "Sono consentiti al massimo 150 caratteri.")]
    public string? Indirizzo { get; set; }

    [StringLength(10, ErrorMessage = "Sono consentiti al massimo 10 caratteri.")]
    public string? CAP { get; set; }

    [StringLength(100, ErrorMessage = "Sono consentiti al massimo 100 caratteri.")]
    public string? Citta { get; set; }

    [StringLength(10, ErrorMessage = "Sono consentiti al massimo 10 caratteri.")]
    public string? Provincia { get; set; }

    [StringLength(50, ErrorMessage = "Sono consentiti al massimo 50 caratteri.")]
    public string? Telefono { get; set; }

    [StringLength(150, ErrorMessage = "Sono consentiti al massimo 150 caratteri.")]
    [EmailAddress(ErrorMessage = "Inserire un indirizzo email valido.")]
    public string? Email { get; set; }

    [StringLength(100, ErrorMessage = "Sono consentiti al massimo 100 caratteri.")]
    public string? Referente { get; set; }

    public string? VersioneRigaBase64 { get; set; }

}

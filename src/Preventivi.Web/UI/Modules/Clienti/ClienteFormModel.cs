using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Clienti;

public sealed class ClienteFormModel
{
    [Required]
    [StringLength(50)]
    [Display(Name = "Codice Cliente")]
    public string CodiceCliente { get; set; } = "";

    [Required]
    [StringLength(200)]
    [Display(Name = "Ragione Sociale")]
    public string RagioneSociale { get; set; } = "";


    [StringLength(30)]
    [Display(Name = "Partita IVA")]
    public string? PartitaIVA { get; set; }

    [Display(Name = "Codice Fiscale")]
    [StringLength(30)]
    public string? CodiceFiscale { get; set; }

    [Display(Name = "Indirizzo")]
    [StringLength(200)]
    public string? Indirizzo { get; set; }

    [Display(Name = "CAP")]
    [StringLength(10)]
    public string? CAP { get; set; }

    [Display(Name = "Città")]
    [StringLength(100)]
    public string? Citta { get; set; }

    [Display(Name = "Provincia")]
    [StringLength(10)]
    public string? Provincia { get; set; }

    [Display(Name = "Telefono")]
    [StringLength(50)]
    public string? Telefono { get; set; }

    [Display(Name = "Email")]
    [StringLength(200)]
    [EmailAddress]
    public string? Email { get; set; }

    [Display(Name = "Attivo")]
    public bool Attivo { get; set; } = true;
}
using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Clienti;

public sealed class ClienteFormModel
{
    [Required]
    [Display(Name = "Codice Cliente")]
    [StringLength(30, ErrorMessage = "Il codice cliente puo contenere al massimo {1} caratteri.")]
    public string CodiceCliente { get; set; } = "";

    [Required]
    [Display(Name = "Ragione Sociale")]
    [StringLength(150, ErrorMessage = "La ragione sociale puo contenere al massimo {1} caratteri.")]
    public string RagioneSociale { get; set; } = "";


    [Display(Name = "Partita IVA")]
    [StringLength(20, ErrorMessage = "La partita IVA puo contenere al massimo {1} caratteri.")]
    public string? PartitaIVA { get; set; }

    [Display(Name = "Codice Fiscale")]
    [StringLength(20, ErrorMessage = "Il codice fiscale puo contenere al massimo {1} caratteri.")]
    public string? CodiceFiscale { get; set; }

    [Display(Name = "Indirizzo")]
    [StringLength(150, ErrorMessage = "L'indirizzo puo contenere al massimo {1} caratteri.")]
    public string? Indirizzo { get; set; }

    [Display(Name = "CAP")]
    [StringLength(10, ErrorMessage = "Il CAP puo contenere al massimo {1} caratteri.")]
    public string? CAP { get; set; }

    [Display(Name = "Città")]
    [StringLength(100, ErrorMessage = "La citta puo contenere al massimo {1} caratteri.")]
    public string? Citta { get; set; }

    [Display(Name = "Provincia")]
    [StringLength(10, ErrorMessage = "La provincia puo contenere al massimo {1} caratteri.")]
    public string? Provincia { get; set; }

    [Display(Name = "Telefono")]
    [StringLength(50, ErrorMessage = "Il telefono puo contenere al massimo {1} caratteri.")]
    public string? Telefono { get; set; }

    [Display(Name = "Email")]
    [EmailAddress]
    [StringLength(150, ErrorMessage = "L'email puo contenere al massimo {1} caratteri.")]
    public string? Email { get; set; }

    [Display(Name = "Attivo")]
    public bool Attivo { get; set; } = true;
}
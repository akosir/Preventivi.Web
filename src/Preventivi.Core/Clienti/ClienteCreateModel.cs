using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Clienti;

public sealed class ClienteCreateModel
{
    [StringLength(30, ErrorMessage = "Il codice cliente puo contenere al massimo {1} caratteri.")]
    public string CodiceCliente { get; set; } = "";

    [StringLength(150, ErrorMessage = "La ragione sociale puo contenere al massimo {1} caratteri.")]
    public string RagioneSociale { get; set; } = "";

    [StringLength(20, ErrorMessage = "La partita IVA puo contenere al massimo {1} caratteri.")]
    public string? PartitaIVA { get; set; }

    [StringLength(20, ErrorMessage = "Il codice fiscale puo contenere al massimo {1} caratteri.")]
    public string? CodiceFiscale { get; set; }

    [StringLength(150, ErrorMessage = "L'indirizzo puo contenere al massimo {1} caratteri.")]
    public string? Indirizzo { get; set; }

    [StringLength(10, ErrorMessage = "Il CAP puo contenere al massimo {1} caratteri.")]
    public string? CAP { get; set; }

    [StringLength(100, ErrorMessage = "La citta puo contenere al massimo {1} caratteri.")]
    public string? Citta { get; set; }

    [StringLength(10, ErrorMessage = "La provincia puo contenere al massimo {1} caratteri.")]
    public string? Provincia { get; set; }

    [StringLength(50, ErrorMessage = "Il telefono puo contenere al massimo {1} caratteri.")]
    public string? Telefono { get; set; }

    [StringLength(150, ErrorMessage = "L'email puo contenere al massimo {1} caratteri.")]
    public string? Email { get; set; }

    public bool Attivo { get; set; } = true;
}

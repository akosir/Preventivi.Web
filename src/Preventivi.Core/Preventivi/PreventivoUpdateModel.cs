using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoUpdateModel
{
    public int IdPreventivo { get; set; }
    public DateOnly DataPreventivo { get; set; }
    public int? IdCliente { get; set; }
    [StringLength(250, ErrorMessage = "L'oggetto puo contenere al massimo {1} caratteri.")]
    public string Oggetto { get; set; } = string.Empty;
    public string? Note { get; set; }
    [StringLength(30, ErrorMessage = "Lo stato puo contenere al massimo {1} caratteri.")]
    public string Stato { get; set; } = string.Empty;
    public decimal MarkupPercDefault { get; set; }
    public int? IdRichiestaCliente { get; set; }
}

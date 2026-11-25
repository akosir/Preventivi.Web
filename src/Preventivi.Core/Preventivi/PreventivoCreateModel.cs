using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoCreateModel
{
    [Required]
    [StringLength(20, ErrorMessage = "L'origine puo contenere al massimo {1} caratteri.")]
    public string Origine { get; set; } = "Libero";

    public DateOnly DataPreventivo { get; set; }

    public int? IdCliente { get; set; }

    public int? IdRichiestaCliente { get; set; }

    public int? IdModelloPreventivo { get; set; }

    [Required]
    [StringLength(250, ErrorMessage = "L'oggetto puo contenere al massimo {1} caratteri.")]
    public string Oggetto { get; set; } = string.Empty;

    public string? Note { get; set; }

    public decimal MarkupPercDefault { get; set; }
}

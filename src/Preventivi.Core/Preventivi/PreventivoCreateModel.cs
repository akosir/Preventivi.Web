using System.ComponentModel.DataAnnotations;

namespace Preventivi.Core.Preventivi;

public sealed class PreventivoCreateModel
{
    [Required]
    public string Origine { get; set; } = "Libero";

    public DateOnly DataPreventivo { get; set; }

    public int? IdCliente { get; set; }

    public int? IdRichiestaCliente { get; set; }

    public int? IdModelloPreventivo { get; set; }

    [Required]
    [StringLength(250)]
    public string Oggetto { get; set; } = string.Empty;

    public string? Note { get; set; }

    public decimal MarkupPercDefault { get; set; }
}

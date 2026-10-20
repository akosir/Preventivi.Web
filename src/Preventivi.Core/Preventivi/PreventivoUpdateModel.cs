namespace Preventivi.Core.Preventivi;

public sealed class PreventivoUpdateModel
{
    public int IdPreventivo { get; set; }
    public DateOnly DataPreventivo { get; set; }
    public int? IdCliente { get; set; }
    public string Oggetto { get; set; } = string.Empty;
    public string? Note { get; set; }
    public string Stato { get; set; } = string.Empty;
    public decimal MarkupPercDefault { get; set; }
    public int? IdRichiestaCliente { get; set; }
}

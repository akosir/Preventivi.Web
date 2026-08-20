namespace Preventivi.Core.Preventivi;

public sealed class PreventivoDettaglio
{
    public int IdPreventivo { get; set; }

    public int NumeroPreventivo { get; set; }

    public int Anno { get; set; }

    public DateOnly DataPreventivo { get; set; }

    public int? IdCliente { get; set; }

    public string Cliente { get; set; } = string.Empty;

    public string Oggetto { get; set; } = string.Empty;

    public string Note { get; set; } = string.Empty;

    public string Stato { get; set; } = string.Empty;

    public decimal TotaleCosti { get; set; }

    public decimal TotaleVendita { get; set; }

    public decimal MargineValore { get; set; }

    public decimal MarginePerc { get; set; }

    public decimal MarkupPercDefault { get; set; }

    public int? IdRichiestaCliente { get; set; }

    public string NumeroCompleto =>
        $"{Anno}-{NumeroPreventivo:00000}";
}
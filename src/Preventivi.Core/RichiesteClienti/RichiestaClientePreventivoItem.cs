namespace Preventivi.Core.RichiesteClienti;

public sealed class RichiestaClientePreventivoItem
{
    public int IdPreventivo { get; set; }
    public int NumeroPreventivo { get; set; }
    public int Anno { get; set; }
    public DateOnly DataPreventivo { get; set; }
    public string Stato { get; set; } = string.Empty;
    public decimal TotaleVendita { get; set; }

    public string NumeroCompleto => $"{Anno}-{NumeroPreventivo:00000}";
}

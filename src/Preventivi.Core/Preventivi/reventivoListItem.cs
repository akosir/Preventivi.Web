namespace Preventivi.Core.Preventivi;

public sealed class PreventivoListItem
{
    public int IdPreventivo { get; set; }

    public int NumeroPreventivo { get; set; }

    public int Anno { get; set; }

    public DateOnly DataPreventivo { get; set; }

    public string Cliente { get; set; } = string.Empty;

    public string Oggetto { get; set; } = string.Empty;

    public decimal TotaleVendita { get; set; }

    public string Stato { get; set; } = string.Empty;

    public string NumeroCompleto =>
        $"{Anno}-{NumeroPreventivo:00000}";
}
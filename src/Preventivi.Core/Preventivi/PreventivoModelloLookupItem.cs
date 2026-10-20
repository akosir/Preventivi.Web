namespace Preventivi.Core.Preventivi;

public sealed class PreventivoModelloLookupItem
{
    public int IdModelloPreventivo { get; set; }

    public string CodiceModelloPreventivo { get; set; } = string.Empty;

    public string Descrizione { get; set; } = string.Empty;

    public int? IdCliente { get; set; }

    public string Cliente { get; set; } = string.Empty;

    public string Oggetto { get; set; } = string.Empty;
}

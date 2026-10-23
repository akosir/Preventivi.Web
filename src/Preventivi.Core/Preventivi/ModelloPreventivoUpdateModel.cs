namespace Preventivi.Core.Preventivi;

public sealed class ModelloPreventivoUpdateModel
{
    public int IdModelloPreventivo { get; set; }
    public string CodiceModelloPreventivo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public int? IdCliente { get; set; }
    public string? Oggetto { get; set; }
    public string? Note { get; set; }
}

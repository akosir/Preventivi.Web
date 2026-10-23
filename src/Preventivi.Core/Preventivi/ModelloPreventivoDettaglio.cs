namespace Preventivi.Core.Preventivi;

public sealed class ModelloPreventivoDettaglio
{
    public int IdModelloPreventivo { get; set; }
    public string CodiceModelloPreventivo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;
    public int? IdCliente { get; set; }
    public string Cliente { get; set; } = string.Empty;
    public string? Oggetto { get; set; }
    public string? Note { get; set; }
    public bool Attivo { get; set; }
    public DateTime DataCreazione { get; set; }
    public DateTime? DataModifica { get; set; }
}

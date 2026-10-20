namespace Preventivi.Core.Preventivi;

public sealed class FornitoreLookupItem
{
    public int IdFornitore { get; set; }
    public string CodiceFornitore { get; set; } = string.Empty;
    public string RagioneSociale { get; set; } = string.Empty;

    public string Display => $"{CodiceFornitore} - {RagioneSociale}";
}

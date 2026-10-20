namespace Preventivi.Core.Preventivi;

public sealed class ModelloCicloLookupItem
{
    public int IdModelloCiclo { get; set; }
    public string CodiceModelloCiclo { get; set; } = string.Empty;
    public string Descrizione { get; set; } = string.Empty;

    public string Display => $"{CodiceModelloCiclo} - {Descrizione}";
}

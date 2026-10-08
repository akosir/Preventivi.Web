namespace Preventivi.Core.Preventivi;

public sealed class ArticoloLookupItem
{
    public int IdArticolo { get; set; }

    public string CodiceArticolo { get; set; } = string.Empty;

    public string Descrizione { get; set; } = string.Empty;

    public string? Versione { get; set; }

    public string Display =>
        string.IsNullOrWhiteSpace(Versione)
            ? $"{CodiceArticolo} - {Descrizione}"
            : $"{CodiceArticolo} - {Descrizione} ({Versione})";
}

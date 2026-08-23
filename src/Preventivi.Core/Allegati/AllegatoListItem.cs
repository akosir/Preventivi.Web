namespace Preventivi.Core.Allegati;

public sealed class AllegatoListItem
{
    public int IdAllegato { get; init; }

    public string TipoAllegato { get; init; } = "";

    public string? Descrizione { get; init; }

    public string NomeFileOriginale { get; init; } = "";

    public string? Estensione { get; init; }

    public DateOnly DataAllegato { get; init; }

    public string? UtenteInserimento { get; init; }
}
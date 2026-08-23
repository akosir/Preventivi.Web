namespace Preventivi.Core.Allegati;

public sealed class AllegatoDettaglio
{
    public int IdAllegato { get; init; }

    public string Entita { get; init; } = "";

    public int IdEntita { get; init; }

    public string? TipoAllegato { get; init; }

    public string? Descrizione { get; init; }

    public string NomeFileOriginale { get; init; } = "";

    public string NomeFileArchiviato { get; init; } = "";

    public string PercorsoFile { get; init; } = "";

    public string? Estensione { get; init; }

    public DateOnly DataAllegato { get; init; }

    public string? UtenteInserimento { get; init; }

    public string? Note { get; init; }
}

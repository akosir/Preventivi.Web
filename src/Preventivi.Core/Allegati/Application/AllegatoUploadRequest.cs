namespace Preventivi.Core.Allegati.Application;

public sealed class AllegatoUploadRequest
{
    public string Entita { get; init; } = "";

    public int IdEntita { get; init; }

    public string? TipoAllegato { get; init; }

    public string? Descrizione { get; init; }

    public string FileTemporaneo { get; init; } = "";

    public string NomeFileOriginale { get; init; } = "";

    public DateOnly DataAllegato { get; init; }

    public string? UtenteInserimento { get; init; }

    public string? Note { get; init; }
}

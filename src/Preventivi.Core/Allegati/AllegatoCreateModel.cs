namespace Preventivi.Core.Allegati;

public sealed class AllegatoCreateModel
{
    public string Entita { get; set; } = "";

    public int IdEntita { get; set; }

    public string? TipoAllegato { get; set; }

    public string? Descrizione { get; set; }

    public string NomeFileOriginale { get; set; } = "";

    public string NomeFileArchiviato { get; set; } = "";

    public string PercorsoFile { get; set; } = "";

    public string? Estensione { get; set; }

    public DateOnly DataAllegato { get; set; }

    public string? UtenteInserimento { get; set; }

    public string? Note { get; set; }

    public long? DimensioneFile { get; set; }
}
namespace Preventivi.Core.Preventivi.Eliminazione;

public sealed class AllegatoEliminazionePreventivo
{
    public int IdAllegato { get; init; }

    public string PercorsoFile { get; init; } = "";

    public string NomeFileArchiviato { get; init; } = "";
}

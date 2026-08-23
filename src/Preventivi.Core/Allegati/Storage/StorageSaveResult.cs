namespace Preventivi.Core.Allegati.Storage;

public sealed class StorageSaveResult
{
    public string PercorsoRelativo { get; init; } = "";

    public string NomeFileArchiviato { get; init; } = "";

    public string NomeFileOriginale { get; init; } = "";

    public string Estensione { get; init; } = "";

    public long DimensioneFile { get; init; }
}

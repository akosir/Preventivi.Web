namespace Preventivi.Core.Allegati.Storage;

public sealed class StorageOpenRequest
{
    public string PercorsoRelativo { get; set; } = "";

    public string NomeFileArchiviato { get; set; } = "";

    public string NomeFileOriginale { get; set; } = "";
}
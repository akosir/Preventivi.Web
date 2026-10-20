namespace Preventivi.Core.Allegati.Storage;

public sealed class StorageQuarantineResult
{
    public string PercorsoRelativoOriginale { get; init; } = "";

    public string NomeFileArchiviatoOriginale { get; init; } = "";

    public string PercorsoRelativoQuarantena { get; init; } = "";

    public string NomeFileQuarantena { get; init; } = "";
}

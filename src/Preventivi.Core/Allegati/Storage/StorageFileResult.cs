namespace Preventivi.Core.Allegati.Storage;

public sealed class StorageFileResult
{
    public Stream Stream { get; init; } = Stream.Null;

    public string NomeFileOriginale { get; init; } = "";

    public string Estensione { get; init; } = "";

    public long DimensioneFile { get; init; }
}
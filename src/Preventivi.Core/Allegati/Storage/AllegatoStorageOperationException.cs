namespace Preventivi.Core.Allegati.Storage;

public sealed class AllegatoStorageOperationException : AllegatoStorageException
{
    public AllegatoStorageOperationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

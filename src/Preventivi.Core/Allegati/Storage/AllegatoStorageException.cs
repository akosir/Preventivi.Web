namespace Preventivi.Core.Allegati.Storage;

public abstract class AllegatoStorageException : InvalidOperationException
{
    protected AllegatoStorageException(string message)
        : base(message)
    {
    }

    protected AllegatoStorageException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

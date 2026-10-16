namespace Preventivi.Core.Allegati.Storage;

public abstract class AllegatoStorageException : InvalidOperationException
{
    protected AllegatoStorageException(string message)
        : base(message)
    {
    }
}

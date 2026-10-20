namespace Preventivi.Core.Allegati.Application;

public sealed class AllegatoApplicationException : InvalidOperationException
{
    public AllegatoApplicationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

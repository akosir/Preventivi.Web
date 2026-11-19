namespace Preventivi.Core.Anagrafiche;

public interface IDistintaBaseApplicationService
{
    Task<int> CreaBozzaAsync(
        DistintaRevisioneCreateModel modello,
        CancellationToken cancellationToken = default);

    Task<int> DuplicaAsync(
        DistintaRevisioneDuplicazioneRequest request,
        CancellationToken cancellationToken = default);

    Task ImportaAsync(
        DistintaImportazioneRequest request,
        CancellationToken cancellationToken = default);
}

public sealed class DistintaBaseApplicationException : Exception
{
    public DistintaBaseApplicationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

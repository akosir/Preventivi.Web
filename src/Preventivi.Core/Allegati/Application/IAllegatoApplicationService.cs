using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Core.Allegati.Application;

public interface IAllegatoApplicationService
{
    Task<int> CreaAsync(
        AllegatoUploadRequest request,
        CancellationToken cancellationToken = default);

    Task<StorageFileResult> ApriAsync(
        int idAllegato,
        CancellationToken cancellationToken = default);

    Task EliminaAsync(
        int idAllegato,
        CancellationToken cancellationToken = default);
}

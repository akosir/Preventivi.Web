using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Data.Allegati;

public interface IAllegatoStorageService
{
    Task<StorageSaveResult> SalvaAsync(
        StorageSaveRequest request,
        CancellationToken cancellationToken = default);

    Task<StorageFileResult> ApriAsync(
    StorageOpenRequest request,
    CancellationToken cancellationToken = default);

    Task EliminaAsync(
        string percorsoRelativo,
        string nomeFileArchiviato,
        CancellationToken cancellationToken = default);
}

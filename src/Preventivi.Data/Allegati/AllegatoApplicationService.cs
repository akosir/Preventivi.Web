using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoApplicationService
    : IAllegatoApplicationService
{
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IAllegatoStorageService _storageService;

    public AllegatoApplicationService(
        IAllegatoRepository allegatoRepository,
        IAllegatoStorageService storageService)
    {
        _allegatoRepository = allegatoRepository;
        _storageService = storageService;
    }

    public async Task<StorageFileResult> ApriAsync(
        int idAllegato,
        CancellationToken cancellationToken = default)
    {
        var allegato =
            await _allegatoRepository.GetByIdAsync(
                idAllegato,
                cancellationToken);

        if (allegato is null)
        {
            throw new KeyNotFoundException(
                $"Allegato {idAllegato} non trovato.");
        }

        return await _storageService.ApriAsync(
            new StorageOpenRequest
            {
                PercorsoRelativo = allegato.PercorsoFile,
                NomeFileArchiviato = allegato.NomeFileArchiviato,
                NomeFileOriginale = allegato.NomeFileOriginale
            },
            cancellationToken);
    }

    public async Task EliminaAsync(
        int idAllegato,
        CancellationToken cancellationToken = default)
    {
        var allegato =
            await _allegatoRepository.GetByIdAsync(
                idAllegato,
                cancellationToken);

        if (allegato is null)
        {
            throw new KeyNotFoundException(
                $"Allegato {idAllegato} non trovato.");
        }

        await _storageService.EliminaAsync(
            allegato.PercorsoFile,
            allegato.NomeFileArchiviato,
            cancellationToken);

        await _allegatoRepository.EliminaAsync(
            idAllegato,
            cancellationToken);
    }
}
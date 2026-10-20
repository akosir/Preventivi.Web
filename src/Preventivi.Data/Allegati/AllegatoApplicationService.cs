using Microsoft.Extensions.Logging;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoApplicationService
    : IAllegatoApplicationService
{
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IAllegatoStorageService _storageService;
    private readonly ILogger<AllegatoApplicationService> _logger;

    public AllegatoApplicationService(
        IAllegatoRepository allegatoRepository,
        IAllegatoStorageService storageService,
        ILogger<AllegatoApplicationService> logger)
    {
        _allegatoRepository = allegatoRepository;
        _storageService = storageService;
        _logger = logger;
    }

    public async Task<int> CreaAsync(
        AllegatoUploadRequest request,
        CancellationToken cancellationToken = default)
    {
        var storageResult = await _storageService.SalvaAsync(
            new StorageSaveRequest
            {
                Entita = request.Entita,
                IdEntita = request.IdEntita,
                FileOrigine = request.FileTemporaneo,
                NomeFileOriginale = request.NomeFileOriginale,
                Utente = request.UtenteInserimento
            },
            cancellationToken);

        try
        {
            return await _allegatoRepository.CreaAsync(
                new AllegatoCreateModel
                {
                    Entita = request.Entita,
                    IdEntita = request.IdEntita,
                    TipoAllegato = request.TipoAllegato,
                    Descrizione = request.Descrizione,
                    NomeFileOriginale = storageResult.NomeFileOriginale,
                    PercorsoFile = storageResult.PercorsoRelativo,
                    Estensione = storageResult.Estensione,
                    DataAllegato = request.DataAllegato,
                    UtenteInserimento = request.UtenteInserimento,
                    Note = request.Note,
                    NomeFileArchiviato = storageResult.NomeFileArchiviato,
                    DimensioneFile = storageResult.DimensioneFile
                },
                CancellationToken.None);
        }
        catch (Exception exception)
        {
            try
            {
                await _storageService.EliminaAsync(
                    storageResult.PercorsoRelativo,
                    storageResult.NomeFileArchiviato,
                    CancellationToken.None);
            }
            catch (Exception compensazioneException)
            {
                _logger.LogCritical(
                    compensazioneException,
                    "Compensazione fallita dopo il mancato inserimento SQL di un allegato per {Entita} {IdEntita}.",
                    request.Entita,
                    request.IdEntita);

                throw new AllegatoApplicationException(
                    "L'inserimento dell'allegato non è riuscito e la compensazione dello storage è fallita.",
                    new AggregateException(exception, compensazioneException));
            }

            throw new AllegatoApplicationException(
                "L'inserimento dell'allegato non è riuscito. Il file archiviato è stato rimosso.",
                exception);
        }
    }

    public async Task<StorageFileResult> ApriAsync(
        int idAllegato,
        CancellationToken cancellationToken = default)
    {
        var allegato = await _allegatoRepository.GetByIdAsync(
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
        var allegato = await _allegatoRepository.GetByIdAsync(
            idAllegato,
            cancellationToken);

        if (allegato is null)
        {
            throw new KeyNotFoundException(
                $"Allegato {idAllegato} non trovato.");
        }

        var fileInQuarantena = await _storageService.SpostaInQuarantenaAsync(
            allegato.PercorsoFile,
            allegato.NomeFileArchiviato,
            cancellationToken);

        try
        {
            await _allegatoRepository.EliminaAsync(
                idAllegato,
                CancellationToken.None);
        }
        catch (Exception exception)
        {
            if (fileInQuarantena is not null)
            {
                try
                {
                    await _storageService.RipristinaDaQuarantenaAsync(
                        fileInQuarantena,
                        CancellationToken.None);
                }
                catch (Exception compensazioneException)
                {
                    _logger.LogCritical(
                        compensazioneException,
                        "Ripristino dalla quarantena fallito per l'allegato {IdAllegato}.",
                        idAllegato);

                    throw new AllegatoApplicationException(
                        "L'eliminazione dell'allegato non è riuscita e il ripristino del file è fallito.",
                        new AggregateException(exception, compensazioneException));
                }
            }

            throw new AllegatoApplicationException(
                "L'eliminazione dell'allegato non è riuscita. Il file è stato ripristinato.",
                exception);
        }

        if (fileInQuarantena is null)
        {
            return;
        }

        try
        {
            await _storageService.EliminaDaQuarantenaAsync(
                fileInQuarantena,
                CancellationToken.None);
        }
        catch (Exception exception)
        {
            _logger.LogCritical(
                exception,
                "Eliminazione definitiva dalla quarantena fallita per l'allegato {IdAllegato}.",
                idAllegato);

            throw new AllegatoApplicationException(
                "Il record dell'allegato è stato eliminato, ma la rimozione definitiva del file è fallita.",
                exception);
        }
    }
}

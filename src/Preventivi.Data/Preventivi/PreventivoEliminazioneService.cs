using Microsoft.Extensions.Logging;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Data.Allegati;

namespace Preventivi.Data.Preventivi;

public sealed class PreventivoEliminazioneService
    : IPreventivoEliminazioneService
{
    private readonly IPreventivoEliminazioneRepository _repository;
    private readonly IAllegatoStorageService _storageService;
    private readonly ILogger<PreventivoEliminazioneService> _logger;

    public PreventivoEliminazioneService(
        IPreventivoEliminazioneRepository repository,
        IAllegatoStorageService storageService,
        ILogger<PreventivoEliminazioneService> logger)
    {
        _repository = repository;
        _storageService = storageService;
        _logger = logger;
    }

    public async Task EliminaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<AllegatoEliminazionePreventivo> allegati;
        try
        {
            allegati = await _repository.PreparaAsync(
                tipo,
                idEntita,
                cancellationToken);
        }
        catch (Exception exception)
        {
            throw new PreventivoEliminazioneException(
                "L'eliminazione non può essere eseguita. Verificare che l'elemento esista e, per i componenti, che non contenga figli.",
                exception);
        }

        var fileInQuarantena = new List<(int IdAllegato, StorageQuarantineResult File)>();

        try
        {
            foreach (var allegato in allegati)
            {
                var file = await _storageService.SpostaInQuarantenaAsync(
                    allegato.PercorsoFile,
                    allegato.NomeFileArchiviato,
                    cancellationToken);

                if (file is null)
                {
                    _logger.LogWarning(
                        "File mancante durante l'eliminazione gerarchica dell'allegato {IdAllegato}.",
                        allegato.IdAllegato);
                    continue;
                }

                fileInQuarantena.Add((allegato.IdAllegato, file));
            }
        }
        catch (Exception exception)
        {
            var erroreRipristino = await RipristinaAsync(fileInQuarantena);
            throw CreaEccezioneConCompensazione(
                "L'eliminazione non è iniziata perché non è stato possibile preparare tutti gli allegati.",
                exception,
                erroreRipristino);
        }

        try
        {
            await _repository.EliminaAsync(
                tipo,
                idEntita,
                allegati.Select(allegato => allegato.IdAllegato).ToArray(),
                CancellationToken.None);
        }
        catch (Exception exception)
        {
            var erroreRipristino = await RipristinaAsync(fileInQuarantena);
            throw CreaEccezioneConCompensazione(
                "L'eliminazione non è riuscita. Gli allegati sono stati ripristinati.",
                exception,
                erroreRipristino);
        }

        var erroriPulizia = new List<Exception>();
        foreach (var elemento in fileInQuarantena)
        {
            try
            {
                await _storageService.EliminaDaQuarantenaAsync(
                    elemento.File,
                    CancellationToken.None);
            }
            catch (Exception exception)
            {
                erroriPulizia.Add(exception);
                _logger.LogCritical(
                    exception,
                    "Pulizia finale della quarantena fallita per l'allegato {IdAllegato}.",
                    elemento.IdAllegato);
            }
        }

        if (erroriPulizia.Count > 0)
        {
            throw new PreventivoEliminazioneException(
                "L'elemento è stato eliminato, ma la pulizia finale di alcuni file non è riuscita.",
                new AggregateException(erroriPulizia),
                eliminazioneCompletata: true);
        }
    }

    private async Task<Exception?> RipristinaAsync(
        IReadOnlyList<(int IdAllegato, StorageQuarantineResult File)> fileInQuarantena)
    {
        var errori = new List<Exception>();

        for (var indice = fileInQuarantena.Count - 1; indice >= 0; indice--)
        {
            var elemento = fileInQuarantena[indice];
            try
            {
                await _storageService.RipristinaDaQuarantenaAsync(
                    elemento.File,
                    CancellationToken.None);
            }
            catch (Exception exception)
            {
                errori.Add(exception);
                _logger.LogCritical(
                    exception,
                    "Ripristino dalla quarantena fallito per l'allegato {IdAllegato}.",
                    elemento.IdAllegato);
            }
        }

        return errori.Count == 0 ? null : new AggregateException(errori);
    }

    private static PreventivoEliminazioneException CreaEccezioneConCompensazione(
        string messaggio,
        Exception errorePrincipale,
        Exception? erroreRipristino)
    {
        return new PreventivoEliminazioneException(
            messaggio,
            erroreRipristino is null
                ? errorePrincipale
                : new AggregateException(errorePrincipale, erroreRipristino));
    }
}

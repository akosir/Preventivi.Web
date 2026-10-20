using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Data.Allegati;
using Xunit;

namespace Preventivi.Data.Tests.Allegati;

public sealed class AllegatoApplicationServiceTests
{
    [Fact]
    public async Task CreaAsync_ErroreRepository_EliminaIlFileArchiviato()
    {
        var repository = new RepositoryFinto
        {
            ErroreCreazione = new InvalidOperationException("Errore SQL")
        };
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<AllegatoApplicationException>(() =>
            servizio.CreaAsync(CreaRichiestaUpload()));

        Assert.True(storage.EliminaChiamato);
    }

    [Fact]
    public async Task CreaAsync_CompensazioneFallita_SegnalaErroreApplicativo()
    {
        var repository = new RepositoryFinto
        {
            ErroreCreazione = new InvalidOperationException("Errore SQL")
        };
        var storage = new StorageFinto
        {
            ErroreEliminazione = new IOException("Storage non disponibile")
        };
        var servizio = CreaServizio(repository, storage);

        var exception = await Assert.ThrowsAsync<AllegatoApplicationException>(() =>
            servizio.CreaAsync(CreaRichiestaUpload()));

        Assert.IsType<AggregateException>(exception.InnerException);
    }

    [Fact]
    public async Task EliminaAsync_ErroreRepository_RipristinaIlFile()
    {
        var repository = new RepositoryFinto
        {
            Allegato = CreaAllegato(),
            ErroreEliminazione = new InvalidOperationException("Errore SQL")
        };
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<AllegatoApplicationException>(() =>
            servizio.EliminaAsync(7));

        Assert.True(storage.RipristinaChiamato);
        Assert.False(storage.EliminaQuarantenaChiamato);
    }

    [Fact]
    public async Task EliminaAsync_Successo_EliminaIlFileDallaQuarantena()
    {
        var repository = new RepositoryFinto
        {
            Allegato = CreaAllegato()
        };
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await servizio.EliminaAsync(7);

        Assert.True(repository.EliminaChiamato);
        Assert.True(storage.EliminaQuarantenaChiamato);
        Assert.False(storage.RipristinaChiamato);
    }

    [Fact]
    public async Task EliminaAsync_RipristinoFallito_SegnalaErroreApplicativo()
    {
        var repository = new RepositoryFinto
        {
            Allegato = CreaAllegato(),
            ErroreEliminazione = new InvalidOperationException("Errore SQL")
        };
        var storage = new StorageFinto
        {
            ErroreRipristino = new IOException("Ripristino non riuscito")
        };
        var servizio = CreaServizio(repository, storage);

        var exception = await Assert.ThrowsAsync<AllegatoApplicationException>(() =>
            servizio.EliminaAsync(7));

        Assert.IsType<AggregateException>(exception.InnerException);
    }

    [Fact]
    public async Task EliminaAsync_PuliziaQuarantenaFallita_SegnalaErroreApplicativo()
    {
        var repository = new RepositoryFinto
        {
            Allegato = CreaAllegato()
        };
        var storage = new StorageFinto
        {
            ErroreEliminazioneQuarantena = new IOException("Pulizia non riuscita")
        };
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<AllegatoApplicationException>(() =>
            servizio.EliminaAsync(7));

        Assert.True(repository.EliminaChiamato);
        Assert.True(storage.EliminaQuarantenaChiamato);
    }

    private static AllegatoApplicationService CreaServizio(
        RepositoryFinto repository,
        StorageFinto storage)
    {
        return new AllegatoApplicationService(
            repository,
            storage,
            NullLogger<AllegatoApplicationService>.Instance);
    }

    private static AllegatoUploadRequest CreaRichiestaUpload()
    {
        return new AllegatoUploadRequest
        {
            Entita = AllegatoEntita.Preventivi,
            IdEntita = 1,
            FileTemporaneo = "temporaneo.txt",
            NomeFileOriginale = "prova.txt",
            DataAllegato = new DateOnly(2026, 10, 19)
        };
    }

    private static AllegatoDettaglio CreaAllegato()
    {
        return new AllegatoDettaglio
        {
            IdAllegato = 7,
            Entita = AllegatoEntita.Preventivi,
            IdEntita = 1,
            NomeFileOriginale = "prova.txt",
            NomeFileArchiviato = "archivio.txt",
            PercorsoFile = "Preventivi/2026/1"
        };
    }

    private sealed class RepositoryFinto : IAllegatoRepository
    {
        public AllegatoDettaglio? Allegato { get; init; }

        public Exception? ErroreCreazione { get; init; }

        public Exception? ErroreEliminazione { get; init; }

        public bool EliminaChiamato { get; private set; }

        public Task<int> CreaAsync(
            AllegatoCreateModel allegato,
            CancellationToken cancellationToken = default)
        {
            return ErroreCreazione is null
                ? Task.FromResult(1)
                : Task.FromException<int>(ErroreCreazione);
        }

        public Task EliminaAsync(
            int idAllegato,
            CancellationToken cancellationToken = default)
        {
            EliminaChiamato = true;
            return ErroreEliminazione is null
                ? Task.CompletedTask
                : Task.FromException(ErroreEliminazione);
        }

        public Task<AllegatoDettaglio?> GetByIdAsync(
            int idAllegato,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(Allegato);
        }

        public Task<IReadOnlyList<AllegatoListItem>> GetElencoAsync(
            string entita,
            int idEntita,
            CancellationToken cancellationToken = default)
        {
            throw new NotSupportedException();
        }

        public Task<IReadOnlyList<TipoAllegatoItem>> GetTipiAsync(
            CancellationToken cancellationToken = default)
        {
            throw new NotSupportedException();
        }

    }

    private sealed class StorageFinto : IAllegatoStorageService
    {
        private readonly StorageQuarantineResult _quarantena = new()
        {
            PercorsoRelativoOriginale = "Preventivi/2026/1",
            NomeFileArchiviatoOriginale = "archivio.txt",
            PercorsoRelativoQuarantena = ".quarantena",
            NomeFileQuarantena = "quarantena.txt"
        };

        public Exception? ErroreEliminazione { get; init; }

        public Exception? ErroreRipristino { get; init; }

        public Exception? ErroreEliminazioneQuarantena { get; init; }

        public bool EliminaChiamato { get; private set; }

        public bool RipristinaChiamato { get; private set; }

        public bool EliminaQuarantenaChiamato { get; private set; }

        public Task<StorageSaveResult> SalvaAsync(
            StorageSaveRequest request,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(new StorageSaveResult
            {
                PercorsoRelativo = "Preventivi/2026/1",
                NomeFileArchiviato = "archivio.txt",
                NomeFileOriginale = request.NomeFileOriginale,
                Estensione = ".txt",
                DimensioneFile = 10
            });
        }

        public Task EliminaAsync(
            string percorsoRelativo,
            string nomeFileArchiviato,
            CancellationToken cancellationToken = default)
        {
            EliminaChiamato = true;
            return ErroreEliminazione is null
                ? Task.CompletedTask
                : Task.FromException(ErroreEliminazione);
        }

        public Task<StorageQuarantineResult?> SpostaInQuarantenaAsync(
            string percorsoRelativo,
            string nomeFileArchiviato,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult<StorageQuarantineResult?>(_quarantena);
        }

        public Task RipristinaDaQuarantenaAsync(
            StorageQuarantineResult fileInQuarantena,
            CancellationToken cancellationToken = default)
        {
            RipristinaChiamato = true;
            return ErroreRipristino is null
                ? Task.CompletedTask
                : Task.FromException(ErroreRipristino);
        }

        public Task EliminaDaQuarantenaAsync(
            StorageQuarantineResult fileInQuarantena,
            CancellationToken cancellationToken = default)
        {
            EliminaQuarantenaChiamato = true;
            return ErroreEliminazioneQuarantena is null
                ? Task.CompletedTask
                : Task.FromException(ErroreEliminazioneQuarantena);
        }

        public Task<StorageFileResult> ApriAsync(
            StorageOpenRequest request,
            CancellationToken cancellationToken = default)
        {
            throw new NotSupportedException();
        }
    }
}

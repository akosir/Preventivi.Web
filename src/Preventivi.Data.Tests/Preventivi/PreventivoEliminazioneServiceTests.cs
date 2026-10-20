using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Data.Allegati;
using Preventivi.Data.Preventivi;
using Xunit;

namespace Preventivi.Data.Tests.Preventivi;

public sealed class PreventivoEliminazioneServiceTests
{
    [Fact]
    public async Task EliminaAsync_Successo_ConfermaEdEliminaLaQuarantena()
    {
        var repository = new RepositoryFinto(CreaAllegati(2));
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await servizio.EliminaAsync(TipoEliminazionePreventivo.Componente, 10);

        Assert.True(repository.EliminaChiamato);
        Assert.Equal([1, 2], repository.IdAllegatiRicevuti);
        Assert.Equal(2, storage.FileEliminati.Count);
        Assert.Empty(storage.FileRipristinati);
    }

    [Fact]
    public async Task EliminaAsync_ErroreSql_RipristinaTuttiIFile()
    {
        var repository = new RepositoryFinto(CreaAllegati(2))
        {
            ErroreEliminazione = new InvalidOperationException("Errore SQL")
        };
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<PreventivoEliminazioneException>(() =>
            servizio.EliminaAsync(TipoEliminazionePreventivo.Riga, 3));

        Assert.Equal([2, 1], storage.FileRipristinati);
        Assert.Empty(storage.FileEliminati);
    }

    [Fact]
    public async Task EliminaAsync_FileMancante_EliminaComunqueIlRecordSql()
    {
        var repository = new RepositoryFinto(CreaAllegati(1));
        var storage = new StorageFinto { FileMancante = 1 };
        var servizio = CreaServizio(repository, storage);

        await servizio.EliminaAsync(TipoEliminazionePreventivo.Materiale, 12);

        Assert.True(repository.EliminaChiamato);
        Assert.Equal([1], repository.IdAllegatiRicevuti);
        Assert.Empty(storage.FileEliminati);
    }

    [Fact]
    public async Task EliminaAsync_ErroreStorage_AnnullaPrimaDiSqlERipristinaIPrecedenti()
    {
        var repository = new RepositoryFinto(CreaAllegati(3));
        var storage = new StorageFinto { ErroreSpostamento = 3 };
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<PreventivoEliminazioneException>(() =>
            servizio.EliminaAsync(TipoEliminazionePreventivo.Lavorazione, 15));

        Assert.False(repository.EliminaChiamato);
        Assert.Equal([2, 1], storage.FileRipristinati);
    }

    [Fact]
    public async Task EliminaAsync_ModificaConcorrente_RipristinaTuttiIFile()
    {
        var repository = new RepositoryFinto(CreaAllegati(2))
        {
            ErroreEliminazione = new InvalidOperationException(
                "Gli allegati sono cambiati durante l'operazione.")
        };
        var storage = new StorageFinto();
        var servizio = CreaServizio(repository, storage);

        await Assert.ThrowsAsync<PreventivoEliminazioneException>(() =>
            servizio.EliminaAsync(TipoEliminazionePreventivo.Componente, 10));

        Assert.Equal([2, 1], storage.FileRipristinati);
        Assert.Empty(storage.FileEliminati);
    }

    private static PreventivoEliminazioneService CreaServizio(
        RepositoryFinto repository,
        StorageFinto storage)
    {
        return new PreventivoEliminazioneService(
            repository,
            storage,
            NullLogger<PreventivoEliminazioneService>.Instance);
    }

    private static IReadOnlyList<AllegatoEliminazionePreventivo> CreaAllegati(int quantita)
    {
        return Enumerable.Range(1, quantita)
            .Select(id => new AllegatoEliminazionePreventivo
            {
                IdAllegato = id,
                PercorsoFile = $"Preventivi/2026/{id}",
                NomeFileArchiviato = $"{id}.txt"
            })
            .ToArray();
    }

    private sealed class RepositoryFinto : IPreventivoEliminazioneRepository
    {
        private readonly IReadOnlyList<AllegatoEliminazionePreventivo> _allegati;

        public RepositoryFinto(IReadOnlyList<AllegatoEliminazionePreventivo> allegati)
        {
            _allegati = allegati;
        }

        public Exception? ErroreEliminazione { get; init; }

        public bool EliminaChiamato { get; private set; }

        public IReadOnlyCollection<int> IdAllegatiRicevuti { get; private set; }
            = Array.Empty<int>();

        public Task<IReadOnlyList<AllegatoEliminazionePreventivo>> PreparaAsync(
            TipoEliminazionePreventivo tipo,
            int idEntita,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(_allegati);
        }

        public Task EliminaAsync(
            TipoEliminazionePreventivo tipo,
            int idEntita,
            IReadOnlyCollection<int> idAllegatiAttesi,
            CancellationToken cancellationToken = default)
        {
            EliminaChiamato = true;
            IdAllegatiRicevuti = idAllegatiAttesi;

            return ErroreEliminazione is null
                ? Task.CompletedTask
                : Task.FromException(ErroreEliminazione);
        }
    }

    private sealed class StorageFinto : IAllegatoStorageService
    {
        public int? FileMancante { get; init; }

        public int? ErroreSpostamento { get; init; }

        public List<int> FileRipristinati { get; } = [];

        public List<int> FileEliminati { get; } = [];

        public Task<StorageQuarantineResult?> SpostaInQuarantenaAsync(
            string percorsoRelativo,
            string nomeFileArchiviato,
            CancellationToken cancellationToken = default)
        {
            var id = int.Parse(Path.GetFileNameWithoutExtension(nomeFileArchiviato));
            if (ErroreSpostamento == id)
            {
                return Task.FromException<StorageQuarantineResult?>(
                    new IOException("Storage non disponibile"));
            }

            if (FileMancante == id)
            {
                return Task.FromResult<StorageQuarantineResult?>(null);
            }

            return Task.FromResult<StorageQuarantineResult?>(new StorageQuarantineResult
            {
                PercorsoRelativoOriginale = percorsoRelativo,
                NomeFileArchiviatoOriginale = nomeFileArchiviato,
                PercorsoRelativoQuarantena = ".quarantena",
                NomeFileQuarantena = $"q-{id}.txt"
            });
        }

        public Task RipristinaDaQuarantenaAsync(
            StorageQuarantineResult fileInQuarantena,
            CancellationToken cancellationToken = default)
        {
            FileRipristinati.Add(LeggiId(fileInQuarantena));
            return Task.CompletedTask;
        }

        public Task EliminaDaQuarantenaAsync(
            StorageQuarantineResult fileInQuarantena,
            CancellationToken cancellationToken = default)
        {
            FileEliminati.Add(LeggiId(fileInQuarantena));
            return Task.CompletedTask;
        }

        public Task<StorageSaveResult> SalvaAsync(
            StorageSaveRequest request,
            CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();

        public Task<StorageFileResult> ApriAsync(
            StorageOpenRequest request,
            CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();

        public Task EliminaAsync(
            string percorsoRelativo,
            string nomeFileArchiviato,
            CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();

        private static int LeggiId(StorageQuarantineResult file) =>
            int.Parse(Path.GetFileNameWithoutExtension(file.NomeFileArchiviatoOriginale));
    }
}

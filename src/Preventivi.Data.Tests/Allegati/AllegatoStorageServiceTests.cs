using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.ParametriSistema;
using Preventivi.Data.Allegati;
using Xunit;

namespace Preventivi.Data.Tests.Allegati;

public sealed class AllegatoStorageServiceTests
{
    [Fact]
    public async Task SalvaAsync_EntitaConsentita_SalvaIlFileDentroLaRoot()
    {
        using var ambiente = new AmbienteStorage();
        var origine = ambiente.CreaFileOrigine("contenuto");
        var servizio = ambiente.CreaServizio(ambiente.Root);

        var risultato = await servizio.SalvaAsync(new StorageSaveRequest
        {
            Entita = AllegatoEntita.Preventivi,
            IdEntita = 42,
            FileOrigine = origine,
            NomeFileOriginale = "prova.txt"
        });

        var percorsoSalvato = Path.GetFullPath(Path.Combine(
            ambiente.Root,
            risultato.PercorsoRelativo,
            risultato.NomeFileArchiviato));
        var rootConSeparatore = ambiente.Root + Path.DirectorySeparatorChar;

        Assert.StartsWith(
            rootConSeparatore,
            percorsoSalvato,
            StringComparison.OrdinalIgnoreCase);
        Assert.True(File.Exists(percorsoSalvato));
    }

    [Fact]
    public async Task SalvaAsync_Annullata_NonLasciaFileParziali()
    {
        using var ambiente = new AmbienteStorage();
        var origine = ambiente.CreaFileOrigine(new string('x', 200000));
        var servizio = ambiente.CreaServizio(ambiente.Root);
        using var cancellation = new CancellationTokenSource();
        cancellation.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            servizio.SalvaAsync(
                new StorageSaveRequest
                {
                    Entita = AllegatoEntita.Preventivi,
                    IdEntita = 42,
                    FileOrigine = origine,
                    NomeFileOriginale = "prova.txt"
                },
                cancellation.Token));

        Assert.Empty(Directory.EnumerateFiles(
            ambiente.Root,
            "*",
            SearchOption.AllDirectories));
    }

    [Theory]
    [InlineData("preventivi")]
    [InlineData("Preventivi/../Altro")]
    [InlineData("Altro")]
    public async Task SalvaAsync_EntitaNonConsentita_RifiutaPrimaDellaScrittura(
        string entita)
    {
        using var ambiente = new AmbienteStorage();
        var origine = ambiente.CreaFileOrigine("contenuto");
        var servizio = ambiente.CreaServizio(ambiente.Root);

        await Assert.ThrowsAsync<AllegatoStoragePathException>(() =>
            servizio.SalvaAsync(new StorageSaveRequest
            {
                Entita = entita,
                IdEntita = 1,
                FileOrigine = origine,
                NomeFileOriginale = "prova.txt"
            }));

        Assert.Empty(Directory.EnumerateFileSystemEntries(ambiente.Root));
    }

    [Theory]
    [InlineData("../esterno")]
    [InlineData("Preventivi/../esterno")]
    [InlineData("Preventivi//2026")]
    public async Task ApriAsync_PercorsoRelativoNonValido_RifiutaIlPercorso(
        string percorsoRelativo)
    {
        using var ambiente = new AmbienteStorage();
        var servizio = ambiente.CreaServizio(ambiente.Root);

        await Assert.ThrowsAsync<AllegatoStoragePathException>(() =>
            servizio.ApriAsync(new StorageOpenRequest
            {
                PercorsoRelativo = percorsoRelativo,
                NomeFileArchiviato = "allegato.txt",
                NomeFileOriginale = "allegato.txt"
            }));
    }

    [Theory]
    [InlineData("../allegato.txt")]
    [InlineData("cartella/allegato.txt")]
    [InlineData("cartella\\allegato.txt")]
    public async Task ApriAsync_NomeArchivioNonValido_RifiutaIlPercorso(
        string nomeFileArchiviato)
    {
        using var ambiente = new AmbienteStorage();
        var servizio = ambiente.CreaServizio(ambiente.Root);

        await Assert.ThrowsAsync<AllegatoStoragePathException>(() =>
            servizio.ApriAsync(new StorageOpenRequest
            {
                PercorsoRelativo = "Preventivi/2026/1",
                NomeFileArchiviato = nomeFileArchiviato,
                NomeFileOriginale = "allegato.txt"
            }));
    }

    [Fact]
    public async Task EliminaAsync_PercorsoEsterno_RifiutaESalvaguardaIlFile()
    {
        using var ambiente = new AmbienteStorage();
        var fileEsterno = Path.Combine(ambiente.Base, "esterno.txt");
        await File.WriteAllTextAsync(fileEsterno, "da conservare");
        var servizio = ambiente.CreaServizio(ambiente.Root);

        await Assert.ThrowsAsync<AllegatoStoragePathException>(() =>
            servizio.EliminaAsync("..", "esterno.txt"));

        Assert.True(File.Exists(fileEsterno));
    }

    [Fact]
    public async Task Quarantena_SpostaERipristinaIlFile()
    {
        using var ambiente = new AmbienteStorage();
        var servizio = ambiente.CreaServizio(ambiente.Root);
        var percorsoRelativo = Path.Combine("Preventivi", "2026", "1");
        var cartella = Path.Combine(ambiente.Root, percorsoRelativo);
        Directory.CreateDirectory(cartella);
        var percorsoOriginale = Path.Combine(cartella, "archivio.txt");
        await File.WriteAllTextAsync(percorsoOriginale, "contenuto");

        var quarantena = await servizio.SpostaInQuarantenaAsync(
            percorsoRelativo,
            "archivio.txt");

        Assert.NotNull(quarantena);
        Assert.False(File.Exists(percorsoOriginale));

        await servizio.RipristinaDaQuarantenaAsync(quarantena!);

        Assert.True(File.Exists(percorsoOriginale));
    }

    [Fact]
    public async Task Quarantena_DopoConfermaEliminaDefinitivamenteIlFile()
    {
        using var ambiente = new AmbienteStorage();
        var servizio = ambiente.CreaServizio(ambiente.Root);
        var percorsoRelativo = Path.Combine("Preventivi", "2026", "1");
        var cartella = Path.Combine(ambiente.Root, percorsoRelativo);
        Directory.CreateDirectory(cartella);
        await File.WriteAllTextAsync(
            Path.Combine(cartella, "archivio.txt"),
            "contenuto");

        var quarantena = await servizio.SpostaInQuarantenaAsync(
            percorsoRelativo,
            "archivio.txt");
        await servizio.EliminaDaQuarantenaAsync(quarantena!);

        Assert.Empty(Directory.EnumerateFiles(
            Path.Combine(ambiente.Root, ".quarantena")));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("percorso/relativo")]
    public async Task ApriAsync_RootMancanteONonAssoluta_RestituisceErroreConfigurazione(
        string? root)
    {
        using var ambiente = new AmbienteStorage();
        var servizio = ambiente.CreaServizio(root);

        await Assert.ThrowsAsync<AllegatoStorageConfigurationException>(() =>
            servizio.ApriAsync(new StorageOpenRequest
            {
                PercorsoRelativo = "Preventivi/2026/1",
                NomeFileArchiviato = "allegato.txt",
                NomeFileOriginale = "allegato.txt"
            }));
    }

    private sealed class AmbienteStorage : IDisposable
    {
        public AmbienteStorage()
        {
            Base = Path.Combine(
                Path.GetTempPath(),
                $"Preventivi.Data.Tests-{Guid.NewGuid():N}");
            Root = Path.Combine(Base, "allegati");
            Directory.CreateDirectory(Root);
        }

        public string Base { get; }

        public string Root { get; }

        public AllegatoStorageService CreaServizio(string? root)
        {
            return new AllegatoStorageService(new ParametriRepositoryFinto(root));
        }

        public string CreaFileOrigine(string contenuto)
        {
            var percorso = Path.Combine(Base, $"origine-{Guid.NewGuid():N}.txt");
            File.WriteAllText(percorso, contenuto);
            return percorso;
        }

        public void Dispose()
        {
            if (Directory.Exists(Base))
            {
                Directory.Delete(Base, recursive: true);
            }
        }
    }

    private sealed class ParametriRepositoryFinto : IParametriSistemaRepository
    {
        private readonly string? _root;

        public ParametriRepositoryFinto(string? root)
        {
            _root = root;
        }

        public Task<string?> GetValoreAsync(
            string chiave,
            CancellationToken cancellationToken = default)
        {
            Assert.Equal("PercorsoRootAllegati", chiave);
            return Task.FromResult(_root);
        }
    }
}

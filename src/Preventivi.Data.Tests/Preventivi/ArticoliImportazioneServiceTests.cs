using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Anagrafiche;
using Xunit;

namespace Preventivi.Data.Tests.Preventivi;

public sealed class ArticoliImportazioneServiceTests
{
    [Theory]
    [InlineData("codice", 51)] [InlineData("descrizione", 201)]
    [InlineData("versione", 21)] [InlineData("cliente", 31)] [InlineData("codice", 0)]
    public async Task Anteprima_NonInterrogaDatabaseConLunghezzeErrate(string campo, int lunghezza)
    {
        var repo = new Repository(); var service = Crea(repo);
        var riga = new ArticoloImportazioneRiga(2, "A1", "Prova", null, null, null);
        riga = campo switch
        {
            "codice" => riga with { CodiceArticolo = new string('x', lunghezza) },
            "descrizione" => riga with { Descrizione = new string('x', lunghezza) },
            "versione" => riga with { Versione = new string('x', lunghezza) },
            _ => riga with { CodiceCliente = new string('x', lunghezza) }
        };
        Assert.NotEmpty(await service.ValidaAsync([riga])); Assert.Equal(0, repo.Validazioni); Assert.Equal(0, repo.Scritture);
    }

    [Fact]
    public async Task Anteprima_RestituisceControlliDbSenzaScritture()
    {
        var repo = new Repository { Errori = [new("Articoli", 2, "Codice articolo", "Duplicato")] };
        Assert.Single(await Crea(repo).ValidaAsync([new(2, "A1", "Prova", null, null, null)]));
        Assert.Equal(1, repo.Validazioni); Assert.Equal(0, repo.Scritture);
    }

    [Fact]
    public async Task Conferma_InoltraFileAutoreERigheAllaTransazioneDb()
    {
        var repo = new Repository(); var richiesta = Richiesta();
        Assert.Equal(1, await Crea(repo).ApplicaAsync(richiesta));
        Assert.Same(richiesta, repo.Richiesta); Assert.Equal(1, repo.Scritture);
    }

    [Theory]
    [InlineData("hash")] [InlineData("utente")] [InlineData("nome")] [InlineData("id")]
    public async Task Conferma_MetadatiErrati_NonScrive(string campo)
    {
        var repo = new Repository(); var richiesta = Richiesta();
        richiesta = campo switch
        {
            "hash" => richiesta with { ImprontaSha256 = "MANOMESSA" },
            "utente" => richiesta with { Utente = "" },
            "nome" => richiesta with { NomeFile = "dati.xls" },
            _ => richiesta with { IdImportazione = Guid.Empty }
        };
        await Assert.ThrowsAsync<ArticoliImportazioneException>(() => Crea(repo).ApplicaAsync(richiesta));
        Assert.Equal(0, repo.Scritture);
    }

    private static ArticoliImportazioneRequest Richiesta() => new(Guid.NewGuid(), "Articoli.xlsx", new string('A', 64), "admin", [new(2, "A1", "Prova", null, null, null)]);
    private static ArticoliImportazioneService Crea(Repository repo) => new(repo, NullLogger<ArticoliImportazioneService>.Instance);
    private sealed class Repository : IArticoliImportazioneRepository
    {
        public int Validazioni, Scritture;
        public IReadOnlyList<ArticoliImportazioneErrore> Errori = [];
        public ArticoliImportazioneRequest? Richiesta;
        public Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default)
        { Validazioni++; return Task.FromResult(Errori); }
        public Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default)
        { Scritture++; Richiesta = richiesta; return Task.FromResult(richiesta.Righe.Count); }
    }
}

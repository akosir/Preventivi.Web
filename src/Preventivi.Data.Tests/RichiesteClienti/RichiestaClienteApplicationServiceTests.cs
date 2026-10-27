using Preventivi.Core.RichiesteClienti;
using Preventivi.Data.RichiesteClienti;
using Preventivi.Core.Preventivi;
using Xunit;

namespace Preventivi.Data.Tests.RichiesteClienti;

public sealed class RichiestaClienteApplicationServiceTests
{
    [Fact]
    public async Task CreaAsync_NormalizzaEInoltraLaRichiesta()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);

        var id = await servizio.CreaAsync(new RichiestaClienteCreateModel
        {
            DataRichiesta = new DateOnly(2026, 10, 26),
            IdCliente = 7,
            Oggetto = "  Richiesta prova  ",
            Stato = "Nuova",
            Priorita = "Media",
            Utente = "  admin  "
        });

        Assert.Equal(42, id);
        Assert.NotNull(repository.Creata);
        Assert.Equal("Richiesta prova", repository.Creata.Oggetto);
        Assert.Equal("admin", repository.Creata.Utente);
    }

    [Fact]
    public async Task AggiornaAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaAsync(
            new RichiestaClienteUpdateModel
            {
                IdRichiestaCliente = 1,
                DataRichiesta = new DateOnly(2026, 10, 26),
                IdCliente = 7,
                Oggetto = "Richiesta prova",
                Stato = "Nuova",
                Priorita = "Media",
                Utente = "admin",
                VersioneRiga = [1]
            }));

        Assert.Null(repository.Aggiornata);
    }

    [Fact]
    public async Task AnnullaAsync_InoltraIdentitaVersioneEUtente()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);
        byte[] versione = [1, 2, 3, 4, 5, 6, 7, 8];

        await servizio.AnnullaAsync(9, versione, "admin");

        Assert.Equal(9, repository.IdAnnullata);
        Assert.Equal(versione, repository.VersioneAnnullata);
        Assert.Equal("admin", repository.UtenteAnnullamento);
    }

    [Fact]
    public async Task RiattivaAsync_InoltraIdentitaVersioneEUtente()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);
        byte[] versione = [8, 7, 6, 5, 4, 3, 2, 1];

        await servizio.RiattivaAsync(12, versione, "  admin  ");

        Assert.Equal(12, repository.IdRiattivata);
        Assert.Equal(versione, repository.VersioneRiattivata);
        Assert.Equal("admin", repository.UtenteRiattivazione);
    }

    [Fact]
    public async Task RiattivaAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() =>
            servizio.RiattivaAsync(12, [1], "admin"));

        Assert.Null(repository.IdRiattivata);
    }

    [Fact]
    public async Task CreaPreventivoAsync_RichiestaValida_UsaOperazioneDedicata()
    {
        var repository = new RepositoryFinto();
        var servizio = new RichiestaClienteApplicationService(repository);
        var preventivo = new PreventivoCreateModel
        {
            Origine = "Richiesta",
            IdRichiestaCliente = 11,
            DataPreventivo = new DateOnly(2026, 10, 26),
            Oggetto = "Preventivo da richiesta",
            MarkupPercDefault = 60
        };

        var id = await servizio.CreaPreventivoAsync(preventivo, "admin");

        Assert.Equal(73, id);
        Assert.Same(preventivo, repository.PreventivoCreato);
        Assert.Equal("admin", repository.UtenteCreazionePreventivo);
    }

    private sealed class RepositoryFinto : IRichiestaClienteRepository
    {
        public RichiestaClienteCreateModel? Creata { get; private set; }
        public RichiestaClienteUpdateModel? Aggiornata { get; private set; }
        public int? IdAnnullata { get; private set; }
        public byte[]? VersioneAnnullata { get; private set; }
        public string? UtenteAnnullamento { get; private set; }
        public int? IdRiattivata { get; private set; }
        public byte[]? VersioneRiattivata { get; private set; }
        public string? UtenteRiattivazione { get; private set; }
        public PreventivoCreateModel? PreventivoCreato { get; private set; }
        public string? UtenteCreazionePreventivo { get; private set; }

        public Task<int> CreaAsync(RichiestaClienteCreateModel richiesta, CancellationToken cancellationToken = default)
        {
            Creata = richiesta;
            return Task.FromResult(42);
        }

        public Task AggiornaAsync(RichiestaClienteUpdateModel richiesta, CancellationToken cancellationToken = default)
        {
            Aggiornata = richiesta;
            return Task.CompletedTask;
        }

        public Task AnnullaAsync(int idRichiestaCliente, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default)
        {
            IdAnnullata = idRichiestaCliente;
            VersioneAnnullata = versioneRiga;
            UtenteAnnullamento = utente;
            return Task.CompletedTask;
        }

        public Task RiattivaAsync(int idRichiestaCliente, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default)
        {
            IdRiattivata = idRichiestaCliente;
            VersioneRiattivata = versioneRiga;
            UtenteRiattivazione = utente;
            return Task.CompletedTask;
        }

        public Task<int> CreaPreventivoAsync(PreventivoCreateModel preventivo, string utente, CancellationToken cancellationToken = default)
        {
            PreventivoCreato = preventivo;
            UtenteCreazionePreventivo = utente;
            return Task.FromResult(73);
        }

        public Task<IReadOnlyList<RichiestaClienteListItem>> GetElencoAsync(RichiestaClienteFiltro filtro, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<RichiestaClienteListItem>>([]);

        public Task<RichiestaClienteDettaglio?> GetDettaglioAsync(int idRichiestaCliente, CancellationToken cancellationToken = default) =>
            Task.FromResult<RichiestaClienteDettaglio?>(null);

        public Task<IReadOnlyList<RichiestaClientePreventivoItem>> GetPreventiviAsync(int idRichiestaCliente, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<RichiestaClientePreventivoItem>>([]);

        public Task<IReadOnlyList<RichiestaClienteCampionaturaItem>> GetCampionatureAsync(int idRichiestaCliente, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<RichiestaClienteCampionaturaItem>>([]);
    }
}

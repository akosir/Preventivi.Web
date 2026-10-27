using Preventivi.Core.Campionature;
using Preventivi.Data.Campionature;
using Xunit;

namespace Preventivi.Data.Tests.Campionature;

public sealed class CampionaturaApplicationServiceTests
{
    [Fact]
    public async Task CreaAsync_NormalizzaEInoltraLaCampionatura()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        var id = await servizio.CreaAsync(new CampionaturaCreateModel
        {
            DataCampionatura = new DateOnly(2026, 10, 27),
            IdRichiestaCliente = 4,
            Oggetto = "  Campione prova  ",
            DescrizioneCampione = "  Descrizione  ",
            Stato = "Aperta",
            Priorita = "Media",
            Utente = "  admin  "
        });

        Assert.Equal(51, id);
        Assert.NotNull(repository.Creata);
        Assert.Equal("Campione prova", repository.Creata.Oggetto);
        Assert.Equal("Descrizione", repository.Creata.DescrizioneCampione);
        Assert.Equal("admin", repository.Creata.Utente);
    }

    [Fact]
    public async Task AggiornaAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaAsync(
            new CampionaturaUpdateModel
            {
                IdCampionatura = 8,
                DataCampionatura = new DateOnly(2026, 10, 27),
                IdRichiestaCliente = 4,
                Oggetto = "Campione prova",
                Stato = "Aperta",
                Priorita = "Media",
                Utente = "admin",
                VersioneRiga = [1]
            }));

        Assert.Null(repository.Aggiornata);
    }

    [Fact]
    public async Task AggiornaAsync_ModelloValido_InoltraVersione()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);
        byte[] versione = [1, 2, 3, 4, 5, 6, 7, 8];

        await servizio.AggiornaAsync(new CampionaturaUpdateModel
        {
            IdCampionatura = 8,
            DataCampionatura = new DateOnly(2026, 10, 27),
            IdRichiestaCliente = 4,
            Oggetto = "Campione prova",
            Stato = "In Verifica",
            Priorita = "Alta",
            Utente = "admin",
            VersioneRiga = versione
        });

        Assert.NotNull(repository.Aggiornata);
        Assert.Equal(8, repository.Aggiornata.IdCampionatura);
        Assert.Equal(versione, repository.Aggiornata.VersioneRiga);
    }

    private sealed class RepositoryFinto : ICampionaturaRepository
    {
        public CampionaturaCreateModel? Creata { get; private set; }
        public CampionaturaUpdateModel? Aggiornata { get; private set; }

        public Task<int> CreaAsync(CampionaturaCreateModel campionatura, CancellationToken cancellationToken = default)
        {
            Creata = campionatura;
            return Task.FromResult(51);
        }

        public Task AggiornaAsync(CampionaturaUpdateModel campionatura, CancellationToken cancellationToken = default)
        {
            Aggiornata = campionatura;
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<CampionaturaListItem>> GetElencoAsync(CampionaturaFiltro filtro, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaListItem>>([]);

        public Task<CampionaturaDettaglio?> GetDettaglioAsync(int idCampionatura, CancellationToken cancellationToken = default) =>
            Task.FromResult<CampionaturaDettaglio?>(null);

        public Task<IReadOnlyList<CampionaturaRichiestaLookupItem>> GetRichiesteAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaRichiestaLookupItem>>([]);

        public Task<IReadOnlyList<CampionaturaPreventivoLookupItem>> GetPreventiviAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaPreventivoLookupItem>>([]);

        public Task<IReadOnlyList<CampionaturaVarianteLookupItem>> GetVariantiAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaVarianteLookupItem>>([]);
    }
}

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
    public async Task CreaAsync_StatoDiversoDaAperta_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.CreaAsync(
            new CampionaturaCreateModel
            {
                DataCampionatura = new DateOnly(2026, 11, 2),
                IdRichiestaCliente = 4,
                Oggetto = "Campione prova",
                Stato = "In Lavorazione",
                Priorita = "Media",
                Utente = "admin"
            }));

        Assert.Null(repository.Creata);
    }

    [Fact]
    public async Task CreaAsync_ConsegnaEffettivaPresente_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.CreaAsync(
            new CampionaturaCreateModel
            {
                DataCampionatura = new DateOnly(2026, 11, 2),
                IdRichiestaCliente = 4,
                Oggetto = "Campione prova",
                Stato = "Aperta",
                Priorita = "Media",
                DataConsegnaCampione = new DateOnly(2026, 11, 2),
                Utente = "admin"
            }));

        Assert.Null(repository.Creata);
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

    [Theory]
    [InlineData("Aperta", "In Lavorazione", true)]
    [InlineData("Aperta", "Chiusa", false)]
    [InlineData("In Lavorazione", "In Verifica", true)]
    [InlineData("In Verifica", "Inviata al Cliente", true)]
    [InlineData("Inviata al Cliente", "Approvata", true)]
    [InlineData("Approvata", "Chiusa", true)]
    [InlineData("Chiusa", "Aperta", false)]
    public void TransizioneCampionaturaOrdinariaConsentita_RispettaLaMatrice(
        string statoCorrente,
        string nuovoStato,
        bool atteso)
    {
        Assert.Equal(
            atteso,
            CampionaturaValori.TransizioneOrdinariaConsentita(statoCorrente, nuovoStato));
    }

    [Fact]
    public async Task AggiornaStatoAsync_NormalizzaEInoltraLaCorrezione()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await servizio.AggiornaStatoAsync(new CampionaturaStatoUpdateModel
        {
            IdCampionatura = 8,
            Stato = " In Verifica ",
            VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
            Utente = " admin ",
            Amministratore = true,
            MotivazioneCorrezione = " Correzione stato errato "
        });

        Assert.NotNull(repository.StatoCampionaturaAggiornato);
        Assert.Equal("In Verifica", repository.StatoCampionaturaAggiornato.Stato);
        Assert.Equal("admin", repository.StatoCampionaturaAggiornato.Utente);
        Assert.Equal(
            "Correzione stato errato",
            repository.StatoCampionaturaAggiornato.MotivazioneCorrezione);
    }

    [Fact]
    public async Task AggiornaStatoAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoAsync(
            new CampionaturaStatoUpdateModel
            {
                IdCampionatura = 8,
                Stato = "In Verifica",
                VersioneRiga = [1],
                Utente = "admin"
            }));

        Assert.Null(repository.StatoCampionaturaAggiornato);
    }

    [Fact]
    public async Task AggiornaStatoAsync_InvioSenzaConsegna_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoAsync(
            new CampionaturaStatoUpdateModel
            {
                IdCampionatura = 8,
                Stato = "Inviata al Cliente",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = "operatore"
            }));

        Assert.Null(repository.StatoCampionaturaAggiornato);
    }

    [Fact]
    public async Task AggiornaStatoAsync_ApprovazioneConEsitoNegativo_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoAsync(
            new CampionaturaStatoUpdateModel
            {
                IdCampionatura = 8,
                Stato = "Approvata",
                Esito = "Negativo",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = "operatore"
            }));

        Assert.Null(repository.StatoCampionaturaAggiornato);
    }

    [Fact]
    public async Task AggiornaStatoAsync_MotivazioneNonAdmin_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoAsync(
            new CampionaturaStatoUpdateModel
            {
                IdCampionatura = 8,
                Stato = "In Verifica",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = "operatore",
                MotivazioneCorrezione = "Tentativo non consentito"
            }));

        Assert.Null(repository.StatoCampionaturaAggiornato);
    }

    [Fact]
    public async Task CreaRilievoAsync_NormalizzaEInoltraIlRilievo()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        var id = await servizio.CreaRilievoAsync(new CampionaturaRilievoCreateModel
        {
            IdCampionatura = 8,
            DataRilevazione = new DateOnly(2026, 10, 29),
            IdTipoProblematica = 2,
            DescrizioneProblema = "  Difetto bordo  ",
            Gravita = "  Alta  ",
            SoluzioneProposta = "  Rifilare  ",
            Utente = "  admin  "
        });

        Assert.Equal(71, id);
        Assert.NotNull(repository.RilievoCreato);
        Assert.Equal("Difetto bordo", repository.RilievoCreato.DescrizioneProblema);
        Assert.Equal("Alta", repository.RilievoCreato.Gravita);
        Assert.Equal("Rifilare", repository.RilievoCreato.SoluzioneProposta);
        Assert.Equal("admin", repository.RilievoCreato.Utente);
    }

    [Fact]
    public async Task AggiornaStatoRilievoAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoRilievoAsync(
            new CampionaturaRilievoStatoUpdateModel
            {
                IdRilievoCampionatura = 7,
                Stato = "In Analisi",
                VersioneRiga = [1],
                Utente = "admin"
            }));

        Assert.Null(repository.StatoRilievoAggiornato);
    }

    [Theory]
    [InlineData("Aperto", "In Analisi", true)]
    [InlineData("Aperto", "Chiuso", false)]
    [InlineData("In Analisi", "Soluzione Proposta", true)]
    [InlineData("Soluzione Proposta", "Risolto", true)]
    [InlineData("Risolto", "Chiuso", true)]
    [InlineData("Chiuso", "In Analisi", false)]
    public void TransizioneOrdinariaConsentita_RispettaLaMatrice(
        string statoCorrente,
        string nuovoStato,
        bool atteso)
    {
        Assert.Equal(
            atteso,
            CampionaturaRilievoValori.TransizioneOrdinariaConsentita(
                statoCorrente,
                nuovoStato));
    }

    [Fact]
    public async Task AggiornaStatoRilievoAsync_CorrezioneAdmin_NormalizzaMotivazione()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await servizio.AggiornaStatoRilievoAsync(
            new CampionaturaRilievoStatoUpdateModel
            {
                IdRilievoCampionatura = 7,
                Stato = "In Analisi",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = " admin ",
                Amministratore = true,
                MotivazioneCorrezione = " Stato assegnato per errore "
            });

        Assert.NotNull(repository.StatoRilievoAggiornato);
        Assert.Equal("Stato assegnato per errore", repository.StatoRilievoAggiornato.MotivazioneCorrezione);
        Assert.Equal("admin", repository.StatoRilievoAggiornato.Utente);
    }

    [Fact]
    public async Task AggiornaStatoRilievoAsync_MotivazioneNonAdmin_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.AggiornaStatoRilievoAsync(
            new CampionaturaRilievoStatoUpdateModel
            {
                IdRilievoCampionatura = 7,
                Stato = "In Analisi",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = "operatore",
                MotivazioneCorrezione = "Tentativo non consentito"
            }));

        Assert.Null(repository.StatoRilievoAggiornato);
    }

    [Fact]
    public async Task CreaAdeguamentoAsync_NormalizzaENonApplicaIlPreventivo()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        var id = await servizio.CreaAdeguamentoAsync(new CampionaturaAdeguamentoCreateModel
        {
            IdRilievoCampionatura = 7,
            DescrizioneAdeguamento = "  Aggiornare il materiale  ",
            ImpattoCostoStimato = 12.50m,
            ImpattoVenditaStimato = 20m,
            VersioneRilievo = [1, 2, 3, 4, 5, 6, 7, 8],
            Utente = "  admin  "
        });

        Assert.Equal(81, id);
        Assert.NotNull(repository.AdeguamentoCreato);
        Assert.Equal("Aggiornare il materiale", repository.AdeguamentoCreato.DescrizioneAdeguamento);
        Assert.Equal("admin", repository.AdeguamentoCreato.Utente);
    }

    [Fact]
    public async Task AggiornaRilievoAsync_NormalizzaEInoltraIlRilievo()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await servizio.AggiornaRilievoAsync(new CampionaturaRilievoUpdateModel
        {
            IdRilievoCampionatura = 7,
            IdCampionatura = 8,
            DataRilevazione = new DateOnly(2026, 10, 29),
            IdTipoProblematica = 2,
            DescrizioneProblema = "  Difetto aggiornato  ",
            Gravita = "Media",
            VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
            Utente = "  admin  "
        });

        Assert.NotNull(repository.RilievoAggiornato);
        Assert.Equal("Difetto aggiornato", repository.RilievoAggiornato.DescrizioneProblema);
        Assert.Equal("admin", repository.RilievoAggiornato.Utente);
    }

    [Fact]
    public async Task EliminaRilievoAsync_VersioneNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.EliminaRilievoAsync(
            new CampionaturaRilievoDeleteModel
            {
                IdRilievoCampionatura = 7,
                VersioneRiga = [1]
            }));

        Assert.Null(repository.RilievoEliminato);
    }

    [Fact]
    public async Task AggiornaAdeguamentoAsync_NormalizzaEInoltraLAdeguamento()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await servizio.AggiornaAdeguamentoAsync(new CampionaturaAdeguamentoUpdateModel
        {
            IdAdeguamento = 9,
            DescrizioneAdeguamento = "  Modificare il materiale  ",
            Note = "  Verificare il costo  ",
            VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
            Utente = "  admin  "
        });

        Assert.NotNull(repository.AdeguamentoAggiornato);
        Assert.Equal("Modificare il materiale", repository.AdeguamentoAggiornato.DescrizioneAdeguamento);
        Assert.Equal("Verificare il costo", repository.AdeguamentoAggiornato.Note);
        Assert.Equal("admin", repository.AdeguamentoAggiornato.Utente);
    }

    [Fact]
    public async Task EliminaAdeguamentoAsync_VersioneRilievoNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.EliminaAdeguamentoAsync(
            new CampionaturaAdeguamentoDeleteModel
            {
                IdAdeguamento = 9,
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                VersioneRilievo = [1],
                Utente = "admin"
            }));

        Assert.Null(repository.AdeguamentoEliminato);
    }

    [Fact]
    public async Task PreparaAdeguamentoAsync_NormalizzaEInoltraLaPreparazione()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        var idVariante = await servizio.PreparaAdeguamentoAsync(
            new CampionaturaAdeguamentoPreparaModel
            {
                IdAdeguamento = 9,
                CodiceVariante = "  ADEG-00009  ",
                DescrizioneVariante = "  Variante di adeguamento  ",
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                Utente = "  admin  "
            });

        Assert.Equal(91, idVariante);
        Assert.NotNull(repository.AdeguamentoPreparato);
        Assert.Equal("ADEG-00009", repository.AdeguamentoPreparato.CodiceVariante);
        Assert.Equal("Variante di adeguamento", repository.AdeguamentoPreparato.DescrizioneVariante);
        Assert.Equal("admin", repository.AdeguamentoPreparato.Utente);
    }

    [Fact]
    public async Task ConfermaAdeguamentoAsync_VersioneRilievoNonValida_NonChiamaRepository()
    {
        var repository = new RepositoryFinto();
        var servizio = new CampionaturaApplicationService(repository);

        await Assert.ThrowsAsync<ArgumentException>(() => servizio.ConfermaAdeguamentoAsync(
            new CampionaturaAdeguamentoConfermaModel
            {
                IdAdeguamento = 9,
                VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8],
                VersioneRilievo = [1],
                Utente = "admin"
            }));

        Assert.Null(repository.AdeguamentoConfermato);
    }

    private sealed class RepositoryFinto : ICampionaturaRepository
    {
        public CampionaturaCreateModel? Creata { get; private set; }
        public CampionaturaUpdateModel? Aggiornata { get; private set; }
        public CampionaturaStatoUpdateModel? StatoCampionaturaAggiornato { get; private set; }
        public CampionaturaRilievoCreateModel? RilievoCreato { get; private set; }
        public CampionaturaRilievoStatoUpdateModel? StatoRilievoAggiornato { get; private set; }
        public CampionaturaRilievoUpdateModel? RilievoAggiornato { get; private set; }
        public CampionaturaRilievoDeleteModel? RilievoEliminato { get; private set; }
        public CampionaturaAdeguamentoCreateModel? AdeguamentoCreato { get; private set; }
        public CampionaturaAdeguamentoUpdateModel? AdeguamentoAggiornato { get; private set; }
        public CampionaturaAdeguamentoDeleteModel? AdeguamentoEliminato { get; private set; }
        public CampionaturaAdeguamentoPreparaModel? AdeguamentoPreparato { get; private set; }
        public CampionaturaAdeguamentoAnnullaPreparazioneModel? PreparazioneAnnullata { get; private set; }
        public CampionaturaAdeguamentoConfermaModel? AdeguamentoConfermato { get; private set; }

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

        public Task AggiornaStatoAsync(CampionaturaStatoUpdateModel campionatura, CancellationToken cancellationToken = default)
        {
            StatoCampionaturaAggiornato = campionatura;
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<CampionaturaCorrezioneStatoListItem>> GetCorrezioniStatoAsync(
            int idCampionatura,
            CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaCorrezioneStatoListItem>>([]);

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

        public Task<IReadOnlyList<CampionaturaRilievoListItem>> GetRilieviAsync(int idCampionatura, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaRilievoListItem>>([]);

        public Task<CampionaturaRilievoDettaglio?> GetRilievoAsync(int idRilievoCampionatura, CancellationToken cancellationToken = default) =>
            Task.FromResult<CampionaturaRilievoDettaglio?>(null);

        public Task<IReadOnlyList<CampionaturaTipoProblematicaLookupItem>> GetTipiProblematicheAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaTipoProblematicaLookupItem>>([]);

        public Task<IReadOnlyList<CampionaturaProblematicaStandardLookupItem>> GetProblematicheStandardAsync(CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaProblematicaStandardLookupItem>>([]);

        public Task<int> CreaRilievoAsync(CampionaturaRilievoCreateModel rilievo, CancellationToken cancellationToken = default)
        {
            RilievoCreato = rilievo;
            return Task.FromResult(71);
        }

        public Task AggiornaStatoRilievoAsync(CampionaturaRilievoStatoUpdateModel rilievo, CancellationToken cancellationToken = default)
        {
            StatoRilievoAggiornato = rilievo;
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<CampionaturaRilievoCorrezioneStatoListItem>> GetCorrezioniStatoRilievoAsync(
            int idRilievoCampionatura,
            CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaRilievoCorrezioneStatoListItem>>([]);

        public Task AggiornaRilievoAsync(CampionaturaRilievoUpdateModel rilievo, CancellationToken cancellationToken = default)
        {
            RilievoAggiornato = rilievo;
            return Task.CompletedTask;
        }

        public Task EliminaRilievoAsync(CampionaturaRilievoDeleteModel rilievo, CancellationToken cancellationToken = default)
        {
            RilievoEliminato = rilievo;
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<CampionaturaAdeguamentoListItem>> GetAdeguamentiAsync(int idCampionatura, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<CampionaturaAdeguamentoListItem>>([]);

        public Task<int> CreaAdeguamentoAsync(CampionaturaAdeguamentoCreateModel adeguamento, CancellationToken cancellationToken = default)
        {
            AdeguamentoCreato = adeguamento;
            return Task.FromResult(81);
        }

        public Task<CampionaturaAdeguamentoDettaglio?> GetAdeguamentoAsync(int idAdeguamento, CancellationToken cancellationToken = default) =>
            Task.FromResult<CampionaturaAdeguamentoDettaglio?>(null);

        public Task AggiornaAdeguamentoAsync(CampionaturaAdeguamentoUpdateModel adeguamento, CancellationToken cancellationToken = default)
        {
            AdeguamentoAggiornato = adeguamento;
            return Task.CompletedTask;
        }

        public Task EliminaAdeguamentoAsync(CampionaturaAdeguamentoDeleteModel adeguamento, CancellationToken cancellationToken = default)
        {
            AdeguamentoEliminato = adeguamento;
            return Task.CompletedTask;
        }

        public Task<int> PreparaAdeguamentoAsync(CampionaturaAdeguamentoPreparaModel adeguamento, CancellationToken cancellationToken = default)
        {
            AdeguamentoPreparato = adeguamento;
            return Task.FromResult(91);
        }

        public Task AnnullaPreparazioneAdeguamentoAsync(CampionaturaAdeguamentoAnnullaPreparazioneModel adeguamento, CancellationToken cancellationToken = default)
        {
            PreparazioneAnnullata = adeguamento;
            return Task.CompletedTask;
        }

        public Task ConfermaAdeguamentoAsync(CampionaturaAdeguamentoConfermaModel adeguamento, CancellationToken cancellationToken = default)
        {
            AdeguamentoConfermato = adeguamento;
            return Task.CompletedTask;
        }
    }
}

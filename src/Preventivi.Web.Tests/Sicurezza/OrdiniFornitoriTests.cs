using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.Pages.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class OrdiniFornitoriTests
{
    [Theory]
    [InlineData("Inviato")]
    [InlineData("Parziale")]
    [InlineData("Ricevuto")]
    [InlineData("Annullato")]
    public async Task SalvaTestata_OrdineNonInBozza_NonInvocaScritture(string stato)
    {
        var pagina = new ModificaModel(new RepositoryNonBozza(stato), null!, NullLogger<ModificaModel>.Instance);
        var risultato = await pagina.OnPostAsync(7, CancellationToken.None);
        Assert.IsType<RedirectToPageResult>(risultato);
    }

    [Theory]
    [InlineData("Inviato")]
    [InlineData("Parziale")]
    [InlineData("Ricevuto")]
    [InlineData("Annullato")]
    public async Task SalvaRiga_OrdineNonInBozza_NonInvocaScritture(string stato)
    {
        var pagina = new RigaModel(new RepositoryNonBozza(stato), null!, NullLogger<RigaModel>.Instance);
        var risultato = await pagina.OnPostAsync(7, null, CancellationToken.None);
        Assert.IsType<RedirectToPageResult>(risultato);
    }

    [Theory]
    [InlineData("it-IT")]
    [InlineData("en-US")]
    public void QuantitaFrazionaria_ValidaConLeCultureSupportate(string cultura)
    {
        var precedente = CultureInfo.CurrentCulture;
        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(cultura);
            var modello = new OrdineFornitoreRigaFormModel
            {
                Descrizione = "Materiale di prova", Quantita = 0.0001m, PrezzoUnitario = 2.45m
            };
            var errori = new List<ValidationResult>();
            Assert.True(Validator.TryValidateObject(modello, new ValidationContext(modello), errori, true));
        }
        finally
        {
            CultureInfo.CurrentCulture = precedente;
        }
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Riapertura_Operatore_NegaAccesso(bool post)
    {
        var pagina = new RiapriModel(new RepositoryNonBozza("Inviato"), NullLogger<RiapriModel>.Instance)
        {
            PageContext = Contesto("OPERATORE")
        };
        var risultato = post
            ? await pagina.OnPostAsync(7, CancellationToken.None)
            : await pagina.OnGetAsync(7, CancellationToken.None);
        Assert.IsType<ForbidResult>(risultato);
    }

    [Fact]
    public async Task Riapertura_AdminSenzaMotivazione_NonInvocaScritture()
    {
        var pagina = new RiapriModel(new RepositoryNonBozza("Inviato"), NullLogger<RiapriModel>.Instance)
        {
            PageContext = Contesto("ADMIN"), Versione = Convert.ToBase64String(new byte[8])
        };
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.Contains(nameof(pagina.Motivazione), pagina.ModelState.Keys);
        Assert.False(pagina.ModelState.IsValid);
    }

    [Fact]
    public async Task Riapertura_AdminConRicezioni_NonInvocaScritture()
    {
        var repository = new RepositoryNonBozza("Inviato", righe: [new() { QuantitaRicevuta = 1 }]);
        var pagina = new RiapriModel(repository, NullLogger<RiapriModel>.Instance)
        {
            PageContext = Contesto("ADMIN"), Versione = Convert.ToBase64String(new byte[8]),
            Motivazione = "Correzione di prova"
        };
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.True(pagina.HaRicezioni);
        Assert.False(pagina.ModelState.IsValid);
    }

    [Theory]
    [InlineData("Inviato", null)]
    [InlineData("Bozza", 13)]
    public async Task StampaDocumento_UsaIValoriStorici(string statoCorrente, int? idDocumento)
    {
        var documento = new OrdineFornitoreDocumentoDettaglio
        {
            IdDocumento = 13, IdOrdineFornitore = 7, NumeroVersione = 1,
            TestataJson = """{"IdOrdineFornitore":7,"DataOrdine":"2026-11-24","DataInvio":"2026-11-24T10:00:00","Stato":"Inviato","RagioneSociale":"Fornitore storico","TotaleOrdine":12.34,"VersioneRiga":"AAAAAAAAAAA="}""",
            RigheJson = """[{"IdRigaOrdineFornitore":11,"IdOrdineFornitore":7,"Descrizione":"Materiale storico","Quantita":1.25,"PrezzoUnitario":9.872,"TotaleRiga":12.34,"VersioneRiga":"AAAAAAAAAAA="}]"""
        };
        var pagina = new StampaModel(new RepositoryNonBozza(statoCorrente, documento));
        Assert.IsType<PageResult>(await pagina.OnGetAsync(7, idDocumento, CancellationToken.None));
        Assert.Equal("Fornitore storico", pagina.Ordine!.RagioneSociale);
        Assert.Equal(new DateTime(2026, 11, 24), pagina.Ordine.DataOrdine);
        Assert.Equal(12.34m, pagina.Ordine.TotaleOrdine);
        Assert.Equal(1.25m, Assert.Single(pagina.Righe).Quantita);
        Assert.Equal(8, pagina.Ordine.VersioneRiga.Length);
        Assert.Equal(13, pagina.Documento!.IdDocumento);
    }

    [Fact]
    public async Task StampaDocumento_IdDocumentoNonDisponibile_RestituisceNonTrovato()
    {
        var pagina = new StampaModel(new RepositoryNonBozza("Inviato"));
        Assert.IsType<NotFoundResult>(await pagina.OnGetAsync(7, 999, CancellationToken.None));
    }

    [Fact]
    public async Task StampaOrdineStoricoSenzaCopia_SegnalaIDatiAttuali()
    {
        var pagina = new StampaModel(new RepositoryNonBozza("Inviato"));
        Assert.IsType<PageResult>(await pagina.OnGetAsync(7, null, CancellationToken.None));
        Assert.True(pagina.CopiaStoricaAssente);
        Assert.Null(pagina.Documento);
    }

    private static PageContext Contesto(string ruolo) => new()
    {
        HttpContext = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [new Claim(ClaimTypes.Name, "utente"), new Claim(ClaimTypes.Role, ruolo)], "Test"))
        }
    };

    private sealed class RepositoryNonBozza(string stato, OrdineFornitoreDocumentoDettaglio? documento = null,
        IReadOnlyList<OrdineFornitoreRiga>? righe = null) : IOrdineFornitoreRepository
    {
        public Task<OrdineFornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default) =>
            Task.FromResult<OrdineFornitoreDettaglio?>(new() { IdOrdineFornitore = id, Stato = stato });
        public Task<IReadOnlyList<OrdineFornitoreDettaglio>> GetElencoAsync(OrdineFornitoreFiltro filtro, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<IReadOnlyList<OrdineFornitoreRiga>> GetRigheAsync(int idOrdine, CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<OrdineFornitoreRiga>>(righe ?? []);
        public Task<IReadOnlyList<OrdineFornitoreDipendenza>> GetDipendenzeAsync(int idOrdine, int? idRiga = null, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<int> SalvaAsync(int? id, OrdineFornitoreSalvataggio modello, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task<int> SalvaRigaAsync(int idOrdine, int? idRiga, OrdineFornitoreRigaSalvataggio modello, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task EliminaAsync(int id, byte[] versione, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task EliminaRigaAsync(int idOrdine, int idRiga, byte[] versioneOrdine, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task<IReadOnlyList<OrdineFornitoreDocumento>> GetDocumentiAsync(int idOrdine, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<OrdineFornitoreDocumentoDettaglio?> GetDocumentoAsync(int idOrdine, int? idDocumento = null, CancellationToken cancellationToken = default) =>
            Task.FromResult(documento);
        public Task<int> ConfermaInvioAsync(int idOrdine, byte[] versioneOrdine, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task RiapriAsync(int idOrdine, byte[] versioneOrdine, string motivazione, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
    }
}

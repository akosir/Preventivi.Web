using System.Reflection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Preventivi;
using Xunit;
using ModificaVariante = Preventivi.Web.Pages.Preventivi.Varianti.ModificaModel;
using DettaglioVariante = Preventivi.Web.Pages.Preventivi.Varianti.DettaglioModel;
using NuovaRiga = Preventivi.Web.Pages.Preventivi.Riga.NuovoModel;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class ModificaVariantiTests
{
    [Fact]
    public async Task AperturaModifica_CaricaCodiceDescrizioneENote()
    {
        var stato = new Stato(); var pagina = Modifica(stato);
        Assert.IsType<PageResult>(await pagina.OnGetAsync(CancellationToken.None));
        Assert.Equal("001", pagina.Codice);
        Assert.Equal("Originale", pagina.Descrizione);
        Assert.Equal("Note originali", pagina.Note);
        Assert.True(pagina.VarianteScelta);
        Assert.Equal(0, stato.Salvataggi);
    }

    [Theory]
    [InlineData("Chiuso", true)]
    [InlineData("Inviato", true)]
    [InlineData("Bozza", false)]
    public async Task Modifica_StatoNonModificabile_NonScrive(string statoPreventivo, bool attiva)
    {
        var stato = new Stato(); stato.Preventivo.Stato = statoPreventivo; stato.Variante.Attiva = attiva;
        var pagina = Modifica(stato);
        Assert.IsType<PageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.False(pagina.Modificabile);
        Assert.Equal(0, stato.Salvataggi);
    }

    [Theory]
    [InlineData("codice")]
    [InlineData("descrizione")]
    [InlineData("impronta")]
    public async Task Modifica_DatiNonValidi_NonScrive(string campo)
    {
        var stato = new Stato(); var pagina = Modifica(stato);
        if (campo == "codice") pagina.Codice = " ";
        if (campo == "descrizione") pagina.Descrizione = new string('x',251);
        if (campo == "impronta") pagina.Impronta = "SUPERATA";
        Assert.IsType<PageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(0, stato.Salvataggi);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task ModificaValida_InviaContestoESceltaRichiesta(bool scelta)
    {
        var stato = new Stato(); var pagina = Modifica(stato);
        pagina.VarianteScelta = scelta;
        Assert.IsType<RedirectToPageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Equal(1, stato.Salvataggi);
        Assert.Equal(7, stato.Argomenti![0]); Assert.Equal(11, stato.Argomenti[1]);
        Assert.Equal("002", stato.Argomenti[2]); Assert.Equal("Nuova descrizione", stato.Argomenti[3]);
        Assert.Equal("Nuove note", stato.Argomenti[4]); Assert.Equal("ATTUALE", stato.Argomenti[5]);
        Assert.Equal(scelta, stato.Argomenti[6]);
        Assert.True(stato.Variante.VarianteScelta);
    }

    [Fact]
    public async Task Modifica_ContestoDiAltroPreventivo_NegaAccesso()
    {
        var stato = new Stato(); stato.Variante.IdPreventivo = 99; var pagina = Modifica(stato);
        Assert.IsType<NotFoundResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Equal(0, stato.Salvataggi);
    }

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public async Task ModificaNonValida_ConservaLaSceltaDigitata(bool scelta)
    {
        var stato = new Stato(); var pagina = Modifica(stato);
        pagina.VarianteScelta = scelta;
        pagina.Codice = "";
        Assert.IsType<PageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Equal(scelta, pagina.VarianteScelta);
        Assert.Equal(0, stato.Salvataggi);
    }

    [Fact]
    public async Task Dettaglio_CaricaSoloRigheDelContestoRichiesto()
    {
        var stato = new Stato();
        var pagina = new DettaglioVariante(Repo(stato)) { IdPreventivo=7, IdVariantePreventivo=11 };
        Assert.IsType<PageResult>(await pagina.OnGetAsync(CancellationToken.None));
        Assert.Equal(7, stato.Argomenti![0]); Assert.Equal(11, stato.Argomenti[1]);
        Assert.Equal(42, Assert.Single(pagina.Righe).IdRigaPreventivo);
    }

    [Fact]
    public async Task Dettaglio_ContestoErrato_NonLeggeRighe()
    {
        var stato = new Stato();
        var pagina = new DettaglioVariante(Repo(stato)) { IdPreventivo=99, IdVariantePreventivo=11 };
        Assert.IsType<NotFoundResult>(await pagina.OnGetAsync(CancellationToken.None));
        Assert.Null(stato.Argomenti);
    }

    [Fact]
    public async Task NuovaRiga_ConservaLaVarianteDelContestoValidato()
    {
        var stato = new Stato();
        var pagina = new NuovaRiga(Repo(stato))
        {
            IdPreventivo=7, IdVariantePreventivo=11,
            Riga=new() { IdVariantePreventivo=99, IdTipoRiga=2, DescrizioneVoce="Riga della variante", Quantita=1, CostoUnitarioLibero=10 }
        };
        Assert.IsType<RedirectToPageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Equal(11, stato.RigaCreata!.IdVariantePreventivo);
        Assert.Equal(7, stato.RigaCreata.IdPreventivo);
    }

    [Fact]
    public async Task NuovaRiga_VarianteDiAltroPreventivo_NonCreaRighe()
    {
        var stato = new Stato(); stato.Variante.IdPreventivo=99;
        var pagina = new NuovaRiga(Repo(stato)) { IdPreventivo=7, IdVariantePreventivo=11 };
        Assert.IsType<NotFoundResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Null(stato.RigaCreata);
    }

    private static ModificaVariante Modifica(Stato stato)
    {
        var http=new DefaultHttpContext();
        return new(Repo(stato),NullLogger<ModificaVariante>.Instance)
        {
            IdPreventivo=7,IdVariantePreventivo=11,Codice="002",Descrizione="Nuova descrizione",Note="Nuove note",Impronta="ATTUALE",
            PageContext=new PageContext { HttpContext=http },TempData=new TempDataDictionary(http,new TempDataProvider())
        };
    }

    private static IPreventivoRepository Repo(Stato stato)
    {
        var proxy=DispatchProxy.Create<IPreventivoRepository,Repository>();
        ((Repository)proxy).Stato=stato;
        return proxy;
    }

    public sealed class Stato
    {
        public PreventivoVarianteItem Variante = new() { IdPreventivo=7,IdVariantePreventivo=11,CodiceVariante="001",DescrizioneVariante="Originale",Note="Note originali",Impronta="ATTUALE",Attiva=true,VarianteScelta=true };
        public PreventivoDettaglio Preventivo = new() { IdPreventivo=7,Stato="Bozza" };
        public int Salvataggi;
        public object?[]? Argomenti;
        public PreventivoRigaCreateModel? RigaCreata;
    }

    public class Repository : DispatchProxy
    {
        public Stato Stato = null!;
        protected override object? Invoke(MethodInfo? method,object?[]? args)
        {
            switch(method!.Name)
            {
                case "GetVarianteAsync":return Task.FromResult<PreventivoVarianteItem?>(Stato.Variante);
                case "GetDettaglioAsync":return Task.FromResult<PreventivoDettaglio?>(Stato.Preventivo);
                case "GetRigheVarianteAsync":Stato.Argomenti=args;return Task.FromResult<IReadOnlyList<PreventivoRigaListItem>>([new() { IdRigaPreventivo=42 }]);
                case "AggiornaVarianteAsync":Stato.Argomenti=args;Stato.Salvataggi++;return Task.CompletedTask;
                case "GetTipiRigaAsync":return Task.FromResult<IReadOnlyList<TipoRigaPreventivoItem>>([new() { IdTipoRiga=2,RigaLibera=true }]);
                case "CercaArticoliAsync":return Task.FromResult<IReadOnlyList<ArticoloLookupItem>>([]);
                case "GetModelliCicloAsync":return Task.FromResult<IReadOnlyList<ModelloCicloLookupItem>>([]);
                case "CreaRigaAsync":Stato.RigaCreata=(PreventivoRigaCreateModel)args![0]!;return Task.FromResult(42);
                default:throw new InvalidOperationException(method.Name);
            }
        }
    }

    private sealed class TempDataProvider : ITempDataProvider
    {
        public IDictionary<string,object> LoadTempData(HttpContext context)=>new Dictionary<string,object>();
        public void SaveTempData(HttpContext context,IDictionary<string,object> values) { }
    }
}

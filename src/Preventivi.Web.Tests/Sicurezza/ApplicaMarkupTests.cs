using System.Reflection;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Preventivi;
using Preventivi.Web.Pages.Preventivi;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class ApplicaMarkupTests
{
    [Theory]
    [InlineData("it-IT")]
    [InlineData("en-US")]
    public void LimitiMarkup_ValidiConEntrambeLeCulture(string cultura)
    {
        var precedente = CultureInfo.CurrentCulture;
        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(cultura);
            var (pagina, _) = Crea();
            var contesto = new ValidationContext(pagina) { MemberName = nameof(ApplicaMarkupModel.Markup) };
            Assert.True(Validator.TryValidateProperty(60.25m, contesto, []));
            Assert.False(Validator.TryValidateProperty(10000000m, contesto, []));
        }
        finally { CultureInfo.CurrentCulture = precedente; }
    }

    [Fact]
    public async Task Apertura_ProponePercentualeCorrenteESenzaConferma()
    {
        var (pagina, stato) = Crea(conferma: false);
        Assert.IsType<PageResult>(await pagina.OnGetAsync(7, CancellationToken.None));
        Assert.Equal(60m, pagina.Markup);
        Assert.False(pagina.Conferma);
        Assert.Equal("ANTEPRIMA", pagina.Impronta);
        Assert.Equal(0, stato.Scritture);
    }

    [Fact]
    public async Task ConfermaMancante_NonScriveEConservaValoreDigitato()
    {
        var (pagina, stato) = Crea();
        pagina.Conferma = false;
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(80m, pagina.Markup);
        Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData("Inviato")]
    [InlineData("Accettato")]
    [InlineData("Respinto")]
    [InlineData("In Produzione")]
    [InlineData("Chiuso")]
    [InlineData("Annullato")]
    public async Task StatoNonModificabile_NonScriveAncheConPostDiretto(string statoPreventivo)
    {
        var (pagina, stato) = Crea(statoPreventivo);
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.False(pagina.Modificabile);
        Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(10000000)]
    [InlineData(1.234)]
    public async Task MarkupNonValido_NonScrive(decimal markup)
    {
        var (pagina, stato) = Crea();
        pagina.Markup = markup;
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData("")]
    [InlineData("VERSIONE-PRECEDENTE")]
    public async Task AnteprimaSuperata_NonScrive(string impronta)
    {
        var (pagina, stato) = Crea();
        pagina.Impronta = impronta;
        Assert.IsType<PageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(impronta, pagina.Impronta);
        Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData("Bozza", 0)]
    [InlineData("Da Verificare", 80)]
    [InlineData("Pronto da Inviare", 60.25)]
    public async Task ConfermaValida_InvocaOperazioneAtomicaERitornaAlPreventivo(string statoPreventivo, decimal markup)
    {
        var (pagina, stato) = Crea(statoPreventivo);
        pagina.Markup = markup;
        var risultato = Assert.IsType<RedirectToPageResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.Equal("/Preventivi/Dettaglio", risultato.PageName);
        Assert.Equal(7, risultato.RouteValues!["id"]);
        Assert.Equal(1, stato.Scritture);
        Assert.Equal(7, stato.IdRicevuto);
        Assert.Equal(markup, stato.MarkupRicevuto);
        Assert.Equal("ANTEPRIMA", stato.ImprontaRicevuta);
    }

    [Fact]
    public async Task PreventivoAssente_NonLeggeAnteprimaENonScrive()
    {
        var (pagina, stato) = Crea();
        stato.Esiste = false;
        Assert.IsType<NotFoundResult>(await pagina.OnPostAsync(7, CancellationToken.None));
        Assert.Equal(0, stato.LettureAnteprima);
        Assert.Equal(0, stato.Scritture);
    }

    private static (ApplicaMarkupModel, Stato) Crea(string statoPreventivo = "Bozza", bool conferma = true)
    {
        var stato = new Stato();
        var repository = DispatchProxy.Create<IPreventivoRepository, Repository>();
        ((Repository)repository).Esegui = (nome, argomenti) =>
        {
            switch (nome)
            {
                case "GetDettaglioAsync":
                    return Task.FromResult<PreventivoDettaglio?>(stato.Esiste ? new() { IdPreventivo = 7, Stato = statoPreventivo } : null);
                case "GetAnteprimaMarkupAsync":
                    stato.LettureAnteprima++;
                    return Task.FromResult<IReadOnlyList<PreventivoMarkupAnteprima>>([new()
                    { IdPreventivo = 7, Stato = statoPreventivo, MarkupPercDefault = 60, Impronta = "ANTEPRIMA", IdRigaPreventivo = 1 }]);
                case "ApplicaMarkupAsync":
                    stato.Scritture++;
                    stato.IdRicevuto = (int)argomenti![0]!;
                    stato.MarkupRicevuto = (decimal)argomenti[1]!;
                    stato.ImprontaRicevuta = (string)argomenti[2]!;
                    return Task.CompletedTask;
                default: throw new InvalidOperationException(nome);
            }
        };
        var context = new DefaultHttpContext();
        return (new ApplicaMarkupModel(repository, NullLogger<ApplicaMarkupModel>.Instance)
        {
            PageContext = new PageContext { HttpContext = context },
            TempData = new TempDataDictionary(context, new MemoriaTempData()),
            Markup = 80, Impronta = "ANTEPRIMA", Conferma = conferma
        }, stato);
    }

    private sealed class Stato
    {
        public bool Esiste = true;
        public int Scritture, LettureAnteprima, IdRicevuto;
        public decimal MarkupRicevuto;
        public string ImprontaRicevuta = string.Empty;
    }

    public class Repository : DispatchProxy
    {
        public Func<string, object?[]?, object?> Esegui = null!;
        protected override object? Invoke(MethodInfo? targetMethod, object?[]? args) => Esegui(targetMethod!.Name, args);
    }

    private sealed class MemoriaTempData : ITempDataProvider
    {
        public IDictionary<string, object> LoadTempData(HttpContext context) => new Dictionary<string, object>();
        public void SaveTempData(HttpContext context, IDictionary<string, object> values) { }
    }
}

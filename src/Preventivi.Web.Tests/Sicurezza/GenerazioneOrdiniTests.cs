using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Core.Preventivi;
using Preventivi.Web.Pages.OrdiniFornitori;
using Preventivi.Web.Sicurezza;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class GenerazioneOrdiniTests
{
    [Fact]
    public async Task Anteprima_ProponeResiduoESuggeritoSenzaSelezionareAutomaticamente()
    {
        var (pagina, repository) = Crea();
        Assert.IsType<PageResult>(await pagina.OnGetAsync(CancellationToken.None));
        var elemento = Assert.Single(pagina.Elementi);
        Assert.Equal(6m, elemento.Quantita);
        Assert.Equal(2.5m, elemento.PrezzoUnitario);
        Assert.Equal(8, elemento.IdFornitore);
        Assert.False(elemento.Selezionato);
        Assert.NotEqual(Guid.Empty, pagina.Richiesta);
        Assert.Equal(0, repository.Conferme);
    }

    [Fact]
    public async Task Anteprima_FornitoreSuggeritoNonAttivo_RichiedeScelta()
    {
        var (pagina, repository) = Crea();
        repository.Origini[0].IdFornitoreSuggerito = 99;
        await pagina.OnGetAsync(CancellationToken.None);
        Assert.Null(Assert.Single(pagina.Elementi).IdFornitore);
    }

    [Fact]
    public async Task Conferma_RigaDiAltroPreventivo_NonLeggeOriginiONonScrive()
    {
        var (pagina, repository) = Crea(idPreventivoDellaRiga: 99);
        pagina.IdRigaPreventivo = 3;
        Assert.IsType<NotFoundResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.Equal(0, repository.Letture);
        Assert.Equal(0, repository.Conferme);
    }

    [Theory]
    [InlineData(0, 1, 8)]
    [InlineData(-1, 1, 8)]
    [InlineData(1, -1, 8)]
    [InlineData(1.00001, 1, 8)]
    [InlineData(1, 1, 99)]
    public async Task Conferma_DatiNonValidi_NonScrive(decimal quantita, decimal prezzo, int fornitore)
    {
        var (pagina, repository) = Crea();
        pagina.Elementi = [Elemento(quantita, prezzo, fornitore)];
        Assert.IsType<PageResult>(await pagina.OnPostAsync(CancellationToken.None));
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(0, repository.Conferme);
        Assert.Equal(quantita, pagina.Elementi[0].Quantita);
    }

    [Theory]
    [InlineData("vuota")]
    [InlineData("duplicata")]
    [InlineData("altraOrigine")]
    public async Task Conferma_SelezioneNonValida_NonScrive(string caso)
    {
        var (pagina, repository) = Crea();
        pagina.Elementi = caso == "vuota" ? [] : [Elemento()];
        if (caso == "duplicata") pagina.Elementi.Add(Elemento());
        if (caso == "altraOrigine") pagina.Elementi[0].IdOrigine = 999;
        await pagina.OnPostAsync(CancellationToken.None);
        Assert.False(pagina.ModelState.IsValid);
        Assert.Equal(0, repository.Conferme);
    }

    [Fact]
    public async Task Conferma_InviaIdentitaRichiestaEValoriDiAcquistoConservandoOrigini()
    {
        var (pagina, repository) = Crea();
        pagina.Elementi = [Elemento(2, 7)];
        var richiesta = pagina.Richiesta;
        await pagina.OnPostAsync(CancellationToken.None);
        Assert.True(pagina.ModelState.IsValid);
        Assert.Equal(1, repository.Conferme);
        Assert.Equal(richiesta, repository.Richiesta);
        Assert.Equal(new AcquistoSelezionato("Materiale", 15, new string('A',64), 8, 2, 7), Assert.Single(repository.Ricevuti));
        Assert.Equal(10m, repository.Origini[0].Quantita);
        Assert.Equal(2.5m, repository.Origini[0].PrezzoProposto);
    }

    [Fact]
    public void PaginaGenerazione_RichiedeAnchePermessoPreventivi()
    {
        var attributo = Assert.Single(typeof(GeneraModel).GetCustomAttributes<AuthorizeAttribute>());
        Assert.Equal(AutorizzazioneApplicazione.PolicyPreventivi, attributo.Policy);
    }

    private static GeneraModel.AcquistoForm Elemento(decimal quantita = 2, decimal prezzo = 1, int fornitore = 8) =>
        new() { Selezionato = true, Tipo = "Materiale", IdOrigine = 15, Impronta = new string('A',64),
            IdFornitore = fornitore, Quantita = quantita, PrezzoUnitario = prezzo };

    private static (GeneraModel, Repository) Crea(int idPreventivoDellaRiga = 1)
    {
        var repository = new Repository();
        var preventivi = Proxy<IPreventivoRepository>.Crea((nome, _) => nome switch
        {
            "GetDettaglioAsync" => Task.FromResult<PreventivoDettaglio?>(new() { IdPreventivo = 1 }),
            "GetRigaAsync" => Task.FromResult<PreventivoRigaDettaglio?>(new() { IdPreventivo = idPreventivoDellaRiga }),
            _ => throw new InvalidOperationException(nome)
        });
        var fornitori = Proxy<IFornitoreRepository>.Crea((nome, _) => nome == "GetElencoAsync"
            ? Task.FromResult<IReadOnlyList<FornitoreDettaglio>>([new() { IdFornitore = 8, Attivo = true }])
            : throw new InvalidOperationException(nome));
        return (new GeneraModel(repository, preventivi, fornitori, NullLogger<GeneraModel>.Instance)
        {
            IdPreventivo = 1, Richiesta = Guid.NewGuid(), DataOrdine = new(2026,11,24),
            PageContext = new PageContext { HttpContext = new DefaultHttpContext() }
        }, repository);
    }

    private sealed class Repository : IGenerazioneOrdiniFornitoriRepository
    {
        public AcquistoPreventivo[] Origini { get; } = [new() { Tipo = "Materiale", IdOrigine = 15,
            Quantita = 10, GiaOrdinata = 4, Residuo = 6, PrezzoProposto = 2.5m, IdFornitoreSuggerito = 8, Impronta = new string('A',64) }];
        public int Letture { get; private set; }
        public int Conferme { get; private set; }
        public Guid Richiesta { get; private set; }
        public IReadOnlyList<AcquistoSelezionato> Ricevuti { get; private set; } = [];
        public Task<IReadOnlyList<AcquistoPreventivo>> GetAnteprimaAsync(int id, int? riga, CancellationToken cancellationToken = default)
        { Letture++; return Task.FromResult<IReadOnlyList<AcquistoPreventivo>>(Origini); }
        public Task<IReadOnlyList<OrdineFornitoreDettaglio>> ConfermaAsync(int id, int? riga, Guid richiesta, DateTime data,
            IReadOnlyList<AcquistoSelezionato> selezione, string utente, CancellationToken cancellationToken = default)
        { Conferme++; Richiesta = richiesta; Ricevuti = selezione; return Task.FromResult<IReadOnlyList<OrdineFornitoreDettaglio>>([new() { IdOrdineFornitore = 10 }]); }
    }

    public class Proxy<T> : DispatchProxy where T : class
    {
        private Func<string, object?[]?, object?> risposta = null!;
        public static T Crea(Func<string, object?[]?, object?> risposta)
        {
            var proxy = Create<T, Proxy<T>>();
            ((Proxy<T>)(object)proxy).risposta = risposta;
            return proxy;
        }
        protected override object? Invoke(MethodInfo? targetMethod, object?[]? args) => risposta(targetMethod!.Name, args);
    }
}

using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Pages.Anagrafiche.Articoli;
using Preventivi.Web.Services;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.Tests.Services;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class ImportazioneArticoliTests
{
    [Fact]
    public void Pagina_RichiedePermessoAnagrafiche()
    {
        Assert.Contains(typeof(ImportaModel).GetCustomAttributes(typeof(AuthorizeAttribute), true).Cast<AuthorizeAttribute>(),
            x => x.Policy == AutorizzazioneApplicazione.PolicyAnagrafiche);
    }

    [Fact]
    public async Task Anteprima_ValidaMaNonScrive()
    {
        var stato = new Servizio(); var pagina = Pagina(stato, new EphemeralDataProtectionProvider());
        Carica(pagina, FileValido());
        Assert.IsType<PageResult>(await pagina.OnPostAnteprimaAsync(default));
        Assert.True(pagina.AnteprimaDisponibile); Assert.Single(pagina.Righe);
        Assert.NotEmpty(pagina.Dati.TokenAnteprima); Assert.Equal(1, stato.Validazioni); Assert.Equal(0, stato.Applicazioni);
    }

    [Fact]
    public async Task Anteprima_ErroreDbNonAbilitaConferma()
    {
        var stato = new Servizio { Errori = [new("Articoli", 2, "Codice cliente", "Cliente non attivo")] };
        var pagina = Pagina(stato, new EphemeralDataProtectionProvider()); Carica(pagina, FileValido());
        Assert.IsType<PageResult>(await pagina.OnPostAnteprimaAsync(default));
        Assert.False(pagina.AnteprimaDisponibile); Assert.Single(pagina.Errori); Assert.Equal("", pagina.Dati.TokenAnteprima);
        Assert.Equal(0, stato.Applicazioni);
    }

    [Fact]
    public async Task ConfermaValida_UsaAutoreAutenticatoENomeProtetto()
    {
        var stato = new Servizio(); var protezione = new EphemeralDataProtectionProvider();
        var anteprima = Pagina(stato, protezione); Carica(anteprima, FileValido()); await anteprima.OnPostAnteprimaAsync(default);
        var pagina = Pagina(stato, protezione); pagina.Dati = anteprima.Dati;
        Assert.IsType<RedirectToPageResult>(await pagina.OnPostApplicaAsync(default));
        Assert.Equal(1, stato.Applicazioni); Assert.Equal("admin", stato.Richiesta!.Utente);
        Assert.Equal("Articoli.xlsx", stato.Richiesta.NomeFile); Assert.Equal("0001", Assert.Single(stato.Richiesta.Righe).CodiceArticolo);
    }

    [Theory]
    [InlineData("senzaAnteprima")] [InlineData("file")] [InlineData("token")]
    [InlineData("utente")] [InlineData("scaduta")]
    public async Task ConfermaNonAutorizzata_NonScrive(string caso)
    {
        var stato = new Servizio(); var protezione = new EphemeralDataProtectionProvider();
        var anteprima = Pagina(stato, protezione); Carica(anteprima, FileValido()); await anteprima.OnPostAnteprimaAsync(default);
        var pagina = Pagina(stato, protezione, caso == "utente" ? "altro" : "admin"); pagina.Dati = anteprima.Dati;
        if (caso == "senzaAnteprima") pagina.Dati.TokenAnteprima = "";
        if (caso == "file") pagina.Dati.ContenutoBase64 = Convert.ToBase64String(ArticoliExcelServiceTests.FileConRighe(["MANOMESSO", "Prova"]));
        if (caso == "token") pagina.Dati.TokenAnteprima = "X" + pagina.Dati.TokenAnteprima[1..];
        if (caso == "scaduta") pagina.Dati.TokenAnteprima = protezione.CreateProtector("Preventivi.Articoli.Importazione.Anteprima.v1")
            .ToTimeLimitedDataProtector().Protect(JsonSerializer.Serialize(new ImportaModel.Anteprima(
                ArticoliExcelService.CalcolaImpronta(FileValido()), "Articoli.xlsx", "admin")), DateTimeOffset.UtcNow.AddMinutes(-1));
        Assert.IsType<PageResult>(await pagina.OnPostApplicaAsync(default));
        Assert.False(pagina.ModelState.IsValid); Assert.False(pagina.AnteprimaDisponibile); Assert.Equal(0, stato.Applicazioni);
    }

    [Fact]
    public async Task Conferma_CambiamentoConcorrenteMostraErroreENuovaAnteprimaObbligatoria()
    {
        var stato = new Servizio(); var protezione = new EphemeralDataProtectionProvider();
        var pagina = Pagina(stato, protezione); Carica(pagina, FileValido()); await pagina.OnPostAnteprimaAsync(default);
        stato.Rifiuta = true; stato.Errori = [new("Articoli", 2, "Codice articolo", "Gia presente")];
        Assert.IsType<PageResult>(await pagina.OnPostApplicaAsync(default));
        Assert.Single(pagina.Errori); Assert.False(pagina.ModelState.IsValid);
        Assert.False(pagina.AnteprimaDisponibile); Assert.Empty(pagina.Dati.TokenAnteprima);
    }

    [Theory]
    [InlineData("Articoli.xls", 10)] [InlineData("Articoli.xlsx", 0)] [InlineData("Articoli.xlsx", 2097153)]
    public async Task CaricamentoNonValido_NonLeggeDb(string nome, int dimensione)
    {
        var stato = new Servizio(); var pagina = Pagina(stato, new EphemeralDataProtectionProvider());
        pagina.Dati.File = new FormFile(new MemoryStream(new byte[dimensione]), 0, dimensione, "Dati.File", nome);
        Assert.IsType<PageResult>(await pagina.OnPostAnteprimaAsync(default));
        Assert.False(pagina.ModelState.IsValid); Assert.Equal(0, stato.Validazioni); Assert.Equal(0, stato.Applicazioni);
    }

    private static byte[] FileValido() => ArticoliExcelServiceTests.FileConRighe(["0001", "Prova"]);
    private static void Carica(ImportaModel pagina, byte[] file) =>
        pagina.Dati.File = new FormFile(new MemoryStream(file), 0, file.Length, "Dati.File", "Articoli.xlsx");
    private static ImportaModel Pagina(Servizio stato, IDataProtectionProvider protezione, string utente = "admin")
    {
        var context = new DefaultHttpContext { User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.Name, utente)], "Test")) };
        return new ImportaModel(null!, stato, new ArticoliExcelService(), protezione)
        {
            PageContext = new PageContext { HttpContext = context, ViewData = new ViewDataDictionary(new EmptyModelMetadataProvider(), new ModelStateDictionary()) },
            TempData = new TempDataDictionary(context, new TempDataProvider())
        };
    }
    private sealed class TempDataProvider : ITempDataProvider
    {
        public IDictionary<string, object> LoadTempData(HttpContext context) => new Dictionary<string, object>();
        public void SaveTempData(HttpContext context, IDictionary<string, object> values) { }
    }
    private sealed class Servizio : IArticoliImportazioneService
    {
        public int Validazioni, Applicazioni; public bool Rifiuta;
        public IReadOnlyList<ArticoliImportazioneErrore> Errori = [];
        public ArticoliImportazioneRequest? Richiesta;
        public Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default)
        { Validazioni++; return Task.FromResult(Errori); }
        public Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default)
        {
            Applicazioni++; Richiesta = richiesta;
            if (Rifiuta) throw new ArticoliImportazioneException("Dati cambiati dopo l'anteprima.");
            return Task.FromResult(richiesta.Righe.Count);
        }
    }
}

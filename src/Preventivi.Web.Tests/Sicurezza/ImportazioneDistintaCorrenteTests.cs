using System.IO.Compression;
using System.Reflection;
using System.Security.Claims;
using System.Text.Json;
using System.Xml.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Preventivi.Web.Sicurezza;
using Xunit;
using Importa = Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni.ImportaModel;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class ImportazioneDistintaCorrenteTests
{
    [Fact]
    public void Accesso_RichiedePermessoAnagrafiche() =>
        Assert.Contains(typeof(Importa).GetCustomAttributes<AuthorizeAttribute>(), x => x.Policy == AutorizzazioneApplicazione.PolicyAnagrafiche);

    [Fact]
    public async Task Modello_NomeFileSenzaRevisione()
    {
        var pagina = Pagina(new(), new EphemeralDataProtectionProvider());
        var risultato = Assert.IsType<FileContentResult>(await pagina.OnGetModelloAsync(11, default));
        Assert.Equal("ImportazioneDistinta_ART.xlsx", risultato.FileDownloadName);
    }

    [Fact]
    public async Task Anteprima_MostraTuttiIContenutiESenzaScritture()
    {
        var stato = new Stato(); var pagina = Pagina(stato, new EphemeralDataProtectionProvider());
        Carica(pagina, FileValido());
        Assert.IsType<PageResult>(await pagina.OnPostAnteprimaAsync(11, default));
        Assert.True(pagina.PuoConfermare); Assert.True(pagina.Analisi!.Valida);
        Assert.Equal(2, pagina.Analisi.NodiAlbero.Count);
        Assert.Single(pagina.Analisi.Materiali); Assert.Single(pagina.Analisi.Lavorazioni);
        Assert.Equal("Note materiale", pagina.Analisi.Materiali[0].Note);
        Assert.Equal("Note lavorazione", pagina.Analisi.Lavorazioni[0].Note);
        Assert.NotEmpty(pagina.Dati.TokenAnteprima); Assert.Equal(0, stato.Scritture);
    }

    [Fact]
    public async Task Conferma_UsaContestoAutoreVersioneProtetti()
    {
        var stato = new Stato(); var chiavi = new EphemeralDataProtectionProvider();
        var anteprima = Pagina(stato, chiavi); Carica(anteprima, FileValido());
        await anteprima.OnPostAnteprimaAsync(11, default);
        var pagina = Pagina(stato, chiavi); pagina.Dati = anteprima.Dati;
        Assert.IsType<RedirectToPageResult>(await pagina.OnPostApplicaAsync(11, default));
        Assert.Equal(1, stato.Scritture); Assert.Equal(11, stato.Richesta!.IdRevisioneDistinta);
        Assert.Equal("admin", stato.Richesta.Utente); Assert.Equal("Distinta.xlsx", stato.Richesta.NomeFile);
        Assert.Equal(stato.Distinta.VersioneRiga, stato.Richesta.VersioneRiga);
        Assert.Equal(2, stato.Richesta.Nodi.Count); Assert.Single(stato.Richesta.Materiali); Assert.Single(stato.Richesta.Lavorazioni);
    }

    [Theory]
    [InlineData("vuota")] [InlineData("nonCorrente")] [InlineData("articoloNonAttivo")] [InlineData("assente")]
    public async Task DestinazioneNonConsentita_NonScrive(string caso)
    {
        var stato = new Stato();
        if (caso == "vuota") stato.HaNodi = true;
        if (caso == "nonCorrente") stato.Distinta.Stato = "Superata";
        if (caso == "articoloNonAttivo") stato.ArticoloAttivo = false;
        if (caso == "assente") stato.Assente = true;
        var pagina = Pagina(stato, new EphemeralDataProtectionProvider()); Carica(pagina, FileValido());
        var risultato = await pagina.OnPostAnteprimaAsync(11, default);
        if (caso == "vuota") { Assert.IsType<PageResult>(risultato); Assert.False(pagina.ModelState.IsValid); }
        else if (caso == "assente") Assert.IsType<NotFoundResult>(risultato);
        else Assert.IsType<ForbidResult>(risultato);
        Assert.False(pagina.PuoConfermare); Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData("file")] [InlineData("token")] [InlineData("utente")] [InlineData("destinazione")]
    [InlineData("scaduta")] [InlineData("senzaAnteprima")]
    public async Task ConfermaManipolata_NonScrive(string caso)
    {
        var stato = new Stato(); var chiavi = new EphemeralDataProtectionProvider();
        var file = FileValido(); var anteprima = Pagina(stato, chiavi); Carica(anteprima, file);
        await anteprima.OnPostAnteprimaAsync(11, default);
        var pagina = Pagina(stato, chiavi, caso == "utente" ? "altro" : "admin"); pagina.Dati = anteprima.Dati;
        if (caso == "file") pagina.Dati.ContenutoBase64 = Convert.ToBase64String([1, 2, 3]);
        if (caso == "token") pagina.Dati.TokenAnteprima = "X" + pagina.Dati.TokenAnteprima[1..];
        if (caso == "senzaAnteprima") pagina.Dati.TokenAnteprima = "";
        if (caso == "scaduta") pagina.Dati.TokenAnteprima = chiavi.CreateProtector("Preventivi.Distinte.Importazione.Anteprima.v1")
            .ToTimeLimitedDataProtector().Protect(JsonSerializer.Serialize(new Importa.Anteprima(Guid.NewGuid(), 11, 5, "Distinta.xlsx",
                DistintaBaseExcelService.CalcolaImpronta(file), Convert.ToBase64String(stato.Distinta.VersioneRiga), "admin")), DateTimeOffset.UtcNow.AddMinutes(-1));
        Assert.IsType<PageResult>(await pagina.OnPostApplicaAsync(caso == "destinazione" ? 12 : 11, default));
        Assert.False(pagina.ModelState.IsValid); Assert.False(pagina.PuoConfermare); Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData("versione")] [InlineData("nodi")] [InlineData("materiale")]
    public async Task CambiamentoDopoAnteprima_BloccaLInteroFile(string caso)
    {
        var stato = new Stato(); var chiavi = new EphemeralDataProtectionProvider();
        var anteprima = Pagina(stato, chiavi); Carica(anteprima, FileValido());
        await anteprima.OnPostAnteprimaAsync(11, default);
        if (caso == "versione") stato.Distinta.VersioneRiga = [9, 9, 9, 9, 9, 9, 9, 9];
        if (caso == "nodi") stato.HaNodi = true;
        if (caso == "materiale") stato.MaterialeDisponibile = false;
        var pagina = Pagina(stato, chiavi); pagina.Dati = anteprima.Dati;
        Assert.IsType<PageResult>(await pagina.OnPostApplicaAsync(11, default));
        Assert.False(pagina.ModelState.IsValid); Assert.False(pagina.PuoConfermare); Assert.Equal(0, stato.Scritture);
        if (caso == "materiale") Assert.NotEmpty(pagina.Analisi!.Errori);
    }

    [Theory]
    [InlineData("dati.xls", 10)] [InlineData("dati.xlsx", 0)] [InlineData("dati.xlsx", 2097153)]
    public async Task CaricamentoErrato_NonAbilitaConferma(string nome, int dimensione)
    {
        var stato = new Stato(); var pagina = Pagina(stato, new EphemeralDataProtectionProvider());
        pagina.Dati.File = new FormFile(new MemoryStream(new byte[dimensione]), 0, dimensione, "Dati.File", nome);
        Assert.IsType<PageResult>(await pagina.OnPostAnteprimaAsync(11, default));
        Assert.False(pagina.ModelState.IsValid); Assert.False(pagina.PuoConfermare); Assert.Equal(0, stato.Scritture);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task ConfermaSemplificata_RichiedeStessiValoriDellAnteprima(bool zeroEsplicito)
    {
        var stato = new Stato { CostoMateriale = 3m };
        var chiavi = new EphemeralDataProtectionProvider();
        var anteprima = Pagina(stato, chiavi);
        var template = new DistintaBaseExcelService().CreaModelloSemplificato(Tipi(), Materiali(), Lavorazioni());
        using var output = new MemoryStream(); output.Write(template);
        using (var zip = new ZipArchive(output, ZipArchiveMode.Update, true))
        {
            XNamespace ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
            XDocument doc; using (var input = zip.GetEntry("xl/worksheets/sheet2.xml")!.Open()) doc = XDocument.Load(input);
            doc.Descendants(ns + "sheetData").Single().Elements().Skip(1).Remove();
            zip.GetEntry("xl/worksheets/sheet2.xml")!.Delete();
            using (var entry = zip.CreateEntry("xl/worksheets/sheet2.xml").Open()) doc.Save(entry);
            Aggiungi(zip, "xl/worksheets/sheet2.xml", [["C01", "Supporto", "", "Prodotto finito", "1", "MAT", "2", "", zeroEsplicito ? "0" : ""]]);
        }
        Carica(anteprima, output.ToArray());
        await anteprima.OnPostAnteprimaAsync(11, default);
        Assert.True(anteprima.PuoConfermare);
        stato.CostoMateriale = 9m;
        var conferma = Pagina(stato, chiavi); conferma.Dati = anteprima.Dati;
        await conferma.OnPostApplicaAsync(11, default);
        Assert.Equal(zeroEsplicito ? 1 : 0, stato.Scritture);
        if (zeroEsplicito) Assert.Equal(0m, stato.Richesta!.Materiali[0].CostoUnitario);
        else Assert.False(conferma.PuoConfermare);
    }

    private static Importa Pagina(Stato stato, IDataProtectionProvider chiavi, string utente = "admin")
    {
        var context = new DefaultHttpContext { User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.Name, utente)], "Test")) };
        return new Importa(Proxy<IDistintaBaseRepository>(stato), Proxy<IDistintaBaseApplicationService>(stato), new(),
            NullLogger<Importa>.Instance, Proxy<IArticoloRepository>(stato), chiavi)
        {
            PageContext = new PageContext { HttpContext = context, ViewData = new ViewDataDictionary(new EmptyModelMetadataProvider(), new ModelStateDictionary()) },
            TempData = new TempDataDictionary(context, new TempDataProvider())
        };
    }
    private static T Proxy<T>(Stato stato) where T : class
    { var p = DispatchProxy.Create<T, RepositoryProxy>(); ((RepositoryProxy)(object)p).Stato = stato; return p; }
    private static void Carica(Importa pagina, byte[] file) => pagina.Dati.File = new FormFile(new MemoryStream(file), 0, file.Length, "Dati.File", "Distinta.xlsx");

    private static byte[] FileValido()
    {
        var template = new DistintaBaseExcelService().CreaModello(Tipi(), Materiali(), Lavorazioni());
        using var output = new MemoryStream(); output.Write(template);
        using (var zip = new ZipArchive(output, ZipArchiveMode.Update, true))
        {
            Aggiungi(zip, "xl/worksheets/sheet2.xml", [["R", "", "Prodotto finito", "R", "Radice", "1", "10", "Si", "Note radice"], ["F", "R", "Prodotto finito", "F", "Figlio", "2", "20", "Si", ""]]);
            Aggiungi(zip, "xl/worksheets/sheet3.xml", [["F", "MAT", "3", "0", "1.25", "Note materiale"]]);
            Aggiungi(zip, "xl/worksheets/sheet4.xml", [["F", "LAV", "10", "1", "0.25", "30", "2", "Note lavorazione"]]);
        }
        return output.ToArray();
    }
    private static void Aggiungi(ZipArchive zip, string path, string[][] righe)
    {
        XNamespace ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
        XDocument doc; using (var input = zip.GetEntry(path)!.Open()) doc = XDocument.Load(input);
        for (var r = 0; r < righe.Length; r++)
            doc.Descendants(ns + "sheetData").Single().Add(new XElement(ns + "row", new XAttribute("r", r + 2),
                righe[r].Select((v, c) => new XElement(ns + "c", new XAttribute("r", $"{(char)('A' + c)}{r + 2}"), new XAttribute("t", "inlineStr"), new XElement(ns + "is", new XElement(ns + "t", v))))));
        zip.GetEntry(path)!.Delete(); using var stream = zip.CreateEntry(path).Open(); doc.Save(stream);
    }
    private static IReadOnlyList<TipoNodoDistintaLookupItem> Tipi() => [new() { IdTipoNodo = 1, Descrizione = "Prodotto finito", Attivo = true }];
    private static IReadOnlyList<DistintaMaterialeLookupItem> Materiali() => [new() { IdMateriale = 1, CodiceMateriale = "MAT", Descrizione = "Materiale" }];
    private static IReadOnlyList<DistintaLavorazioneLookupItem> Lavorazioni() => [new() { IdLavorazione = 1, CodiceLavorazione = "LAV", Descrizione = "Lavorazione" }];
    public sealed class Stato
    {
        public DistintaRevisioneDettaglio Distinta = new() { IdRevisioneDistinta = 11, IdArticolo = 5, CodiceArticolo = "ART", Stato = "Pubblicata", VersioneRiga = [1, 2, 3, 4, 5, 6, 7, 8] };
        public bool HaNodi, Assente; public bool ArticoloAttivo = true, MaterialeDisponibile = true;
        public int Scritture; public DistintaImportazioneRequest? Richesta;
        public decimal CostoMateriale;
    }
    public class RepositoryProxy : DispatchProxy
    {
        public Stato Stato = null!;
        protected override object? Invoke(MethodInfo? method, object?[]? args) => method!.Name switch
        {
            "GetRevisioneAsync" => Task.FromResult<DistintaRevisioneDettaglio?>(Stato.Assente ? null : Stato.Distinta),
            "GetDettaglioAsync" => Task.FromResult<ArticoloDettaglio?>(new() { IdArticolo = 5, Attivo = Stato.ArticoloAttivo }),
            "GetNodiAsync" => Task.FromResult<IReadOnlyList<DistintaNodoItem>>(Stato.HaNodi ? [new()] : []),
            "GetTipiNodoAsync" => Task.FromResult(Tipi()),
            "GetMaterialiLookupAsync" => Task.FromResult<IReadOnlyList<DistintaMaterialeLookupItem>>(Stato.MaterialeDisponibile ? [new() { IdMateriale = 1, CodiceMateriale = "MAT", Descrizione = "Materiale", CostoUnitario = Stato.CostoMateriale }] : []),
            "GetLavorazioniLookupAsync" => Task.FromResult(Lavorazioni()),
            "ImportaAsync" => Scrivi((DistintaImportazioneRequest)args![0]!),
            _ => throw new InvalidOperationException(method.Name)
        };
        private Task Scrivi(DistintaImportazioneRequest request) { Stato.Scritture++; Stato.Richesta = request; return Task.CompletedTask; }
    }
    private sealed class TempDataProvider : ITempDataProvider
    {
        public IDictionary<string, object> LoadTempData(HttpContext context) => new Dictionary<string, object>();
        public void SaveTempData(HttpContext context, IDictionary<string, object> values) { }
    }
}

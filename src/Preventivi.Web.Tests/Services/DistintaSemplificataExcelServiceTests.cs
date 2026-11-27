using System.IO.Compression;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Xunit;

namespace Preventivi.Web.Tests.Services;

public sealed class DistintaSemplificataExcelServiceTests
{
    private static readonly XNamespace Ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
    private readonly DistintaBaseExcelService servizio = new();
    private static readonly TipoNodoDistintaLookupItem[] Tipi = [new() { IdTipoNodo = 1, Descrizione = "Componente", Attivo = true }];
    private static readonly DistintaMaterialeLookupItem[] Materiali = [new() { IdMateriale = 1, CodiceMateriale = "MAT", Descrizione = "Carta", CostoUnitario = 2.5m }];
    private static readonly DistintaLavorazioneLookupItem[] Lavorazioni = [new() { IdLavorazione = 1, CodiceLavorazione = "LAV", Descrizione = "Taglio", TempoSetupMinDefault = 5, TempoPezzoMinDefault = 2, CostoOrarioStandard = 30 }];

    [Fact]
    public void Modello_ContieneMenuTabellaEColonneFacoltative()
    {
        using var zip = new ZipArchive(new MemoryStream(servizio.CreaModelloSemplificato(Tipi, Materiali, Lavorazioni)));
        var workbook = Xml(zip, "xl/workbook.xml");
        Assert.Equal(new[] { "Istruzioni", "Distinta", "Supporto" }, workbook.Descendants(Ns + "sheet").Select(x => (string)x.Attribute("name")!));
        Assert.Equal(4, workbook.Descendants(Ns + "definedName").Count());
        var sheet = Xml(zip, "xl/worksheets/sheet2.xml");
        Assert.Equal(4, sheet.Descendants(Ns + "dataValidation").Count());
        Assert.Contains(sheet.Descendants(Ns + "col"), x => (string?)x.Attribute("hidden") == "1");
        var formula = Assert.Single(Xml(zip, "xl/tables/table1.xml").Descendants(Ns + "calculatedColumnFormula")).Value;
        Assert.Contains("[[#This Row],[Codice]]", formula);
        Assert.DoesNotContain("[@", formula);
        var primaRiga = sheet.Descendants(Ns + "c").Single(x => (string?)x.Attribute("r") == "R2").Element(Ns + "f")!.Value;
        Assert.Equal(formula, primaRiga);
        Assert.Contains("TabellaDistinta[[#This Row],[Descrizione]]", primaRiga);
        Assert.DoesNotContain("A2", primaRiga);
        Assert.DoesNotContain("B2", primaRiga);
    }

    [Fact]
    public void RigheRipetute_UnisconoComponenteEDefaultAnagrafica()
    {
        var analisi = Analizza(["C01", "Supporto", "", "Componente", "1", "MAT - Carta", "3"], ["C01", "", "", "", "", "", "", "LAV - Taglio"]);
        Assert.True(analisi.Valida, string.Join("; ", analisi.Errori.Select(x => x.Messaggio)));
        Assert.Single(analisi.Nodi);
        Assert.Equal(2.5m, Assert.Single(analisi.Materiali).CostoUnitario);
        var fase = Assert.Single(analisi.Lavorazioni);
        Assert.Equal(5m, fase.TempoSetupMin);
        Assert.Equal(2m, fase.TempoPezzoMin);
        Assert.Equal(30m, fase.CostoOrario);
        Assert.Equal(10, fase.Sequenza);
    }

    [Fact]
    public void ZeroEsplicito_NonUsaDefault()
    {
        var analisi = Analizza(["C01", "Supporto", "", "Componente", "1", "MAT", "3", "LAV", "0", "0", "0", "0", "0"]);
        Assert.True(analisi.Valida);
        Assert.Equal(0m, Assert.Single(analisi.Materiali).CostoUnitario);
        Assert.Equal(0m, Assert.Single(analisi.Lavorazioni).CostoOrario);
        Assert.Equal(0m, analisi.Lavorazioni[0].TempoSetupMin);
    }

    [Fact]
    public void Padre_AccettaRiferimentoEDescrizione()
    {
        var analisi = Analizza(["C01", "Supporto", "", "Componente", "1"], ["C02", "Figlio", "C01 - Supporto", "Componente", "2"]);
        Assert.True(analisi.Valida);
        Assert.Equal(analisi.Nodi[0].ChiaveNodo, analisi.Nodi[1].ChiavePadre);
    }

    [Theory]
    [InlineData("Diverso", "", "", "", "", "", "")]
    [InlineData("", "", "", "", "MAT", "1", "")]
    [InlineData("", "", "", "", "", "", "")]
    public void RipetizioniAmbigue_SonoRifiutate(string descrizione, string padre, string tipo, string quantita, string materiale, string quantitaMateriale, string lavorazione)
    {
        var analisi = Analizza(["C01", "Supporto", "", "Componente", "1", "MAT", "3"], ["C01", descrizione, padre, tipo, quantita, materiale, quantitaMateriale, lavorazione]);
        Assert.False(analisi.Valida);
        Assert.All(analisi.Errori, e => Assert.Equal("Distinta", e.Foglio));
    }

    [Fact]
    public void CostoNonNumerico_NonDiventaDefault()
    {
        Assert.False(Analizza(["C01", "Supporto", "", "Componente", "1", "MAT", "3", "", "errore"]).Valida);
    }

    [Fact]
    public void Impronta_CambiaSeCambianoIValoriMostrati()
    {
        var prima = Analizza(["C01", "Supporto", "", "Componente", "1", "MAT", "3"]);
        var seconda = Analizza(["C01", "Supporto", "", "Componente", "1", "MAT", "3", "", "9"]);
        Assert.NotEqual(DistintaBaseExcelService.CalcolaImprontaAnalisi(prima), DistintaBaseExcelService.CalcolaImprontaAnalisi(seconda));
    }

    private DistintaImportazioneAnalisi Analizza(params string[][] righe)
    {
        using var stream = new MemoryStream();
        stream.Write(servizio.CreaModelloSemplificato(Tipi, Materiali, Lavorazioni));
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Update, true))
        {
            var documento = Xml(zip, "xl/worksheets/sheet2.xml");
            var data = documento.Root!.Element(Ns + "sheetData")!;
            data.Elements().Skip(1).Remove();
            for (var i = 0; i < righe.Length; i++)
                data.Add(new XElement(Ns + "row", new XAttribute("r", i + 2), righe[i].Select((valore, colonna) =>
                    new XElement(Ns + "c", new XAttribute("r", $"{(char)('A' + colonna)}{i + 2}"), new XAttribute("t", "inlineStr"), new XElement(Ns + "is", new XElement(Ns + "t", valore))))));
            zip.GetEntry("xl/worksheets/sheet2.xml")!.Delete();
            using var output = zip.CreateEntry("xl/worksheets/sheet2.xml").Open();
            documento.Save(output);
        }
        return servizio.Analizza(stream.ToArray(), Tipi, Materiali, Lavorazioni);
    }

    private static XDocument Xml(ZipArchive zip, string path)
    {
        using var input = zip.GetEntry(path)!.Open();
        return XDocument.Load(input);
    }
}

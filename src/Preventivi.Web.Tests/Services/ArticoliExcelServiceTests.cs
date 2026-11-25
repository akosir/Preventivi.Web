using System.IO.Compression;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Xunit;

namespace Preventivi.Web.Tests.Services;

public sealed class ArticoliExcelServiceTests
{
    private static readonly XNamespace Ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";

    [Fact]
    public void Modello_ContieneColonneELookupSoloAttivi()
    {
        var excel = new ArticoliExcelService();
        var file = excel.CreaModello([new() { CodiceCliente = "001", Attivo = true }, new() { CodiceCliente = "NONATTIVO", Attivo = false }]);
        using var zip = new ZipArchive(new MemoryStream(file));
        var workbook = Leggi(zip, "xl/workbook.xml");
        Assert.Contains(workbook.Descendants(Ns + "sheet"), x => (string?)x.Attribute("name") == "Articoli");
        var campi = Leggi(zip, "xl/worksheets/sheet2.xml").Descendants(Ns + "t").Select(x => x.Value).ToArray();
        Assert.Equal(new[] { "Codice articolo", "Descrizione", "Versione articolo", "Codice cliente", "Note tecniche" }, campi);
        var clienti = Leggi(zip, "xl/worksheets/sheet3.xml").ToString();
        Assert.Contains("001", clienti); Assert.DoesNotContain("NONATTIVO", clienti);
        Assert.Contains(Leggi(zip, "xl/styles.xml").Descendants(Ns + "xf"), x => (string?)x.Attribute("numFmtId") == "49");
    }

    [Fact]
    public void Analizza_ConservaZeriTestiUnicodeERigheOriginali()
    {
        var file = FileConRighe(["00001", " Citta e prova <&> ", "01", "00002", "Nota\nseconda riga"]);
        var risultato = new ArticoliExcelService().Analizza(file);
        Assert.True(risultato.Valida);
        var riga = Assert.Single(risultato.Righe);
        Assert.Equal(2, riga.RigaExcel); Assert.Equal("00001", riga.CodiceArticolo);
        Assert.Equal("Citta e prova <&>", riga.Descrizione); Assert.Equal("01", riga.Versione);
        Assert.Equal("00002", riga.CodiceCliente); Assert.Equal("Nota\nseconda riga", riga.NoteTecniche);
    }

    [Fact]
    public void Analizza_AmmetteCampiFacoltativiVuoti()
    {
        var analisi = new ArticoliExcelService().Analizza(FileConRighe(["A1", "Prova"]));
        var riga = Assert.Single(analisi.Righe); Assert.True(analisi.Valida);
        Assert.Null(riga.Versione); Assert.Null(riga.CodiceCliente); Assert.Null(riga.NoteTecniche);
    }

    [Theory]
    [InlineData("intestazione")] [InlineData("duplicata")] [InlineData("formula")]
    [InlineData("cellaSenzaColonna")] [InlineData("foglioAssente")] [InlineData("xmlNonValido")]
    public void Analizza_FileErrato_NonAbilitaConferma(string caso)
    {
        var file = FileConRighe(["A1", "Prova"]);
        file = Modifica(file, zip =>
        {
            var p = caso == "foglioAssente" ? "xl/workbook.xml" : "xl/worksheets/sheet2.xml";
            var xml = Leggi(zip, p);
            if (caso == "foglioAssente") xml.Descendants(Ns + "sheet").Single(x => (string?)x.Attribute("name") == "Articoli").SetAttributeValue("name", "Altro");
            else if (caso == "intestazione") xml.Descendants(Ns + "t").First().Value = "Codice errato";
            else if (caso == "duplicata") xml.Descendants(Ns + "row").First().Elements(Ns + "c").ElementAt(1).Element(Ns + "is")!.Element(Ns + "t")!.Value = "Codice articolo";
            else if (caso == "formula") xml.Descendants(Ns + "row").ElementAt(1).Elements(Ns + "c").First().Add(new XElement(Ns + "f", "1+1"));
            else if (caso == "cellaSenzaColonna") xml.Descendants(Ns + "row").ElementAt(1).Add(Cella("Z2", "Perduta"));
            Scrivi(zip, p, xml);
            if (caso == "xmlNonValido")
            {
                zip.GetEntry(p)!.Delete(); using var writer = new StreamWriter(zip.CreateEntry(p).Open()); writer.Write("<nonvalido");
            }
        });
        var analisi = new ArticoliExcelService().Analizza(file);
        Assert.False(analisi.Valida); Assert.NotEmpty(analisi.Errori);
    }

    [Fact]
    public void Analizza_LeggeStringheCondiviseDiExcel()
    {
        var file = Modifica(FileConRighe(["00001", "Prova"]), zip =>
        {
            var foglio = Leggi(zip, "xl/worksheets/sheet2.xml");
            var cella = foglio.Descendants(Ns + "row").ElementAt(1).Elements(Ns + "c").First();
            cella.RemoveNodes(); cella.SetAttributeValue("t", "s"); cella.Add(new XElement(Ns + "v", 0));
            Scrivi(zip, "xl/worksheets/sheet2.xml", foglio);
            Scrivi(zip, "xl/sharedStrings.xml", new XDocument(new XElement(Ns + "sst", new XElement(Ns + "si", new XElement(Ns + "t", "00001")))));
        });
        Assert.Equal("00001", Assert.Single(new ArticoliExcelService().Analizza(file).Righe).CodiceArticolo);
    }

    [Theory]
    [InlineData(0)] [InlineData(10)] [InlineData(2097153)]
    public void Analizza_FileVuotoCorrottoOTroppoGrande(int lunghezza)
    {
        var risultato = new ArticoliExcelService().Analizza(new byte[lunghezza]);
        Assert.False(risultato.Valida); Assert.NotEmpty(risultato.Errori);
    }

    [Fact]
    public void ModelloVuoto_NonEImportabile()
    {
        Assert.False(new ArticoliExcelService().Analizza(new ArticoliExcelService().CreaModello([])).Valida);
    }

    public static byte[] FileConRighe(params string[][] righe) => Modifica(new ArticoliExcelService().CreaModello([]), zip =>
    {
        var xml = Leggi(zip, "xl/worksheets/sheet2.xml");
        var dati = xml.Descendants(Ns + "sheetData").Single();
        for (var i = 0; i < righe.Length; i++)
            dati.Add(new XElement(Ns + "row", new XAttribute("r", i + 2),
                righe[i].Select((v, c) => Cella($"{(char)('A' + c)}{i + 2}", v))));
        Scrivi(zip, "xl/worksheets/sheet2.xml", xml);
    });
    private static XElement Cella(string riferimento, string valore) => new(Ns + "c", new XAttribute("r", riferimento),
        new XAttribute("t", "inlineStr"), new XElement(Ns + "is", new XElement(Ns + "t", valore)));
    private static XDocument Leggi(ZipArchive zip, string percorso)
    { using var input = zip.GetEntry(percorso)!.Open(); return XDocument.Load(input); }
    private static void Scrivi(ZipArchive zip, string percorso, XDocument xml)
    { zip.GetEntry(percorso)?.Delete(); using var output = zip.CreateEntry(percorso).Open(); xml.Save(output); }
    private static byte[] Modifica(byte[] file, Action<ZipArchive> modifica)
    {
        using var stream = new MemoryStream(); stream.Write(file);
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Update, true)) modifica(zip);
        return stream.ToArray();
    }
}

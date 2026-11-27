using System.IO.Compression;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Xunit;

namespace Preventivi.Web.Tests.Services;

public sealed class DistintaBaseExcelServiceTests
{
    private static readonly XNamespace Spreadsheet = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";

    [Fact]
    public void CreaModello_GeneraLeSezioniObbligatorie()
    {
        var servizio = new DistintaBaseExcelService();
        var contenuto = servizio.CreaModello(Tipi(), Materiali(), Lavorazioni());

        using var archivio = new ZipArchive(new MemoryStream(contenuto), ZipArchiveMode.Read);
        var workbook = CaricaXml(archivio, "xl/workbook.xml");
        var nomi = workbook.Descendants(Spreadsheet + "sheet")
            .Select(x => (string?)x.Attribute("name"))
            .ToArray();

        Assert.Contains("Nodi", nomi);
        Assert.Contains("Materiali", nomi);
        Assert.Contains("Lavorazioni", nomi);
        Assert.Contains("Anagrafica materiali", nomi);
        Assert.Contains("Anagrafica lavorazioni", nomi);
    }

    [Fact]
    public void Analizza_FileValido_RicostruisceGerarchiaEMovimenti()
    {
        var servizio = new DistintaBaseExcelService();
        var contenuto = servizio.CreaModello(Tipi(), Materiali(), Lavorazioni());
        contenuto = AggiungiRighe(contenuto, "xl/worksheets/sheet2.xml",
        [
            ["RADICE", "", "Prodotto finito", "PF", "Prodotto finito", "1.25", "10", "Sì", ""],
            ["FIGLIO", "RADICE", "Componente", "CMP", "Componente", "2,50", "20", "Sì", ""]
        ]);
        contenuto = AggiungiRighe(contenuto, "xl/worksheets/sheet3.xml",
        [
            ["FIGLIO", "MAT-01", "3.5", "2,00", "4.25", ""]
        ]);
        contenuto = AggiungiRighe(contenuto, "xl/worksheets/sheet4.xml",
        [
            ["FIGLIO", "LAV-01", "10", "5", "0.25", "35,00", "2", ""]
        ]);

        var analisi = servizio.Analizza(contenuto, Tipi(), Materiali(), Lavorazioni());

        Assert.True(analisi.Valida, string.Join(Environment.NewLine, analisi.Errori.Select(x => x.Messaggio)));
        Assert.Equal(2, analisi.Nodi.Count);
        Assert.Equal(1.25m, analisi.Nodi[0].QuantitaBase);
        Assert.Equal(2.50m, analisi.Nodi[1].QuantitaBase);
        Assert.Single(analisi.Materiali);
        Assert.Equal(4.25m, analisi.Materiali[0].CostoUnitario);
        Assert.Single(analisi.Lavorazioni);
        Assert.Equal(0.25m, analisi.Lavorazioni[0].TempoPezzoMin);
    }

    [Fact]
    public void Analizza_PadreMancante_IndicaFoglioRigaECampo()
    {
        var servizio = new DistintaBaseExcelService();
        var contenuto = servizio.CreaModello(Tipi(), Materiali(), Lavorazioni());
        contenuto = AggiungiRighe(contenuto, "xl/worksheets/sheet2.xml",
        [
            ["RADICE", "", "Prodotto finito", "PF", "Prodotto finito", "1", "10", "Sì", ""],
            ["FIGLIO", "INESISTENTE", "Componente", "CMP", "Componente", "1", "20", "Sì", ""]
        ]);

        var analisi = servizio.Analizza(contenuto, Tipi(), Materiali(), Lavorazioni());

        var errore = Assert.Single(analisi.Errori, x => x.Campo == "Chiave padre" && x.Riga == 3);
        Assert.Equal("Nodi", errore.Foglio);
        Assert.Contains("non esiste", errore.Messaggio, StringComparison.OrdinalIgnoreCase);
        Assert.False(analisi.Valida);
    }

    [Fact]
    public void Modello_ParlaDiDistintaCorrenteSenzaRevisioni()
    {
        using var archivio = new ZipArchive(new MemoryStream(new DistintaBaseExcelService().CreaModello(Tipi(), Materiali(), Lavorazioni())));
        var testo = CaricaXml(archivio, "xl/worksheets/sheet1.xml").ToString();
        Assert.Contains("distinta corrente", testo);
        Assert.DoesNotContain("bozza", testo, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("revisione", testo, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AnteprimaAlbero_RicostruiscePadriELivelliIndipendentementeDalleRighe()
    {
        var excel = new DistintaBaseExcelService();
        var file = AggiungiRighe(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), "xl/worksheets/sheet2.xml",
        [
            ["FIGLIO", "RADICE", "Componente", "F", "Figlio", "2", "20", "Sì", "Nota figlio"],
            ["RADICE", "", "Prodotto finito", "R", "Radice", "1", "10", "Sì", "Nota radice"],
            ["NIPOTE", "FIGLIO", "Componente", "N", "Nipote", "3", "30", "Sì", ""]
        ]);
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.True(analisi.Valida);
        Assert.Equal(new[] { "RADICE", "FIGLIO", "NIPOTE" }, analisi.NodiAlbero.Select(x => x.Nodo.ChiaveNodo));
        Assert.Equal(new[] { 0, 1, 2 }, analisi.NodiAlbero.Select(x => x.Livello));
        Assert.Equal("Nota figlio", analisi.NodiAlbero[1].Nodo.Note);
        Assert.Equal(2, analisi.NodiAlbero[1].Nodo.RigaExcel);
    }

    [Fact]
    public void AnteprimaAlbero_NonTroncaDopoCentoNodi()
    {
        var excel = new DistintaBaseExcelService();
        var righe = new List<IReadOnlyList<string>> { new[] { "R", "", "Prodotto finito", "R", "Radice", "1", "0", "Sì", "" } };
        righe.AddRange(Enumerable.Range(1, 120).Select(i => (IReadOnlyList<string>)new[] { "F" + i, "R", "Componente", "C" + i, "Figlio " + i, "1", i.ToString(), "Sì", "" }));
        var file = AggiungiRighe(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), "xl/worksheets/sheet2.xml", righe);
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.True(analisi.Valida); Assert.Equal(121, analisi.NodiAlbero.Count);
        Assert.Equal("F120", analisi.NodiAlbero[^1].Nodo.ChiaveNodo);
    }

    [Theory]
    [InlineData("1.23456", "nodo")]
    [InlineData("100000000000000", "nodo")]
    [InlineData("0.001", "setup")]
    [InlineData("1.23456", "materiale")]
    public void PrecisioneNonRappresentabile_BloccaSenzaArrotondare(string valore, string campo)
    {
        var excel = new DistintaBaseExcelService();
        var file = AggiungiRighe(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), "xl/worksheets/sheet2.xml",
            [["R", "", "Prodotto finito", "R", "Radice", campo == "nodo" ? valore : "1", "10", "Sì", ""]]);
        if (campo == "setup") file = AggiungiRighe(file, "xl/worksheets/sheet4.xml", [["R", "LAV-01", "10", valore, "0", "30", "0", ""]]);
        if (campo == "materiale") file = AggiungiRighe(file, "xl/worksheets/sheet3.xml", [["R", "MAT-01", "1", "0", valore, ""]]);
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.False(analisi.Valida);
        Assert.Contains(analisi.Errori, x => x.Messaggio.Contains("Non viene arrotondato"));
        if (campo == "setup") Assert.Equal(0.001m, Assert.Single(analisi.Lavorazioni).TempoSetupMin);
    }

    [Theory]
    [InlineData("ciclo")] [InlineData("duplicato")] [InlineData("radiceNonAttiva")]
    public void GerarchiaNonValida_NonGeneraAlbero(string caso)
    {
        var excel = new DistintaBaseExcelService();
        var file = AggiungiRighe(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), "xl/worksheets/sheet2.xml",
        [
            ["R", caso == "ciclo" ? "F" : "", "Prodotto finito", "R", "Radice", "1", "10", caso == "radiceNonAttiva" ? "No" : "Sì", ""],
            [caso == "duplicato" ? "R" : "F", "R", "Componente", "F", "Figlio", "1", "20", "Sì", ""]
        ]);
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.False(analisi.Valida); Assert.Empty(analisi.NodiAlbero);
    }

    [Fact]
    public void IntestazioneDuplicata_ErroreControllato()
    {
        var excel = new DistintaBaseExcelService();
        var file = ModificaFoglio(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), doc =>
        {
            var celle = doc.Descendants(Spreadsheet + "row").First().Elements(Spreadsheet + "c").ToArray();
            celle[1].Descendants(Spreadsheet + "t").Single().Value = "Chiave nodo";
        });
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.False(analisi.Valida); Assert.Contains(analisi.Errori, x => x.Campo == "Intestazione");
    }

    [Fact]
    public void Formula_NonImportaIlValoreMemorizzato()
    {
        var excel = new DistintaBaseExcelService();
        var file = AggiungiRighe(excel.CreaModello(Tipi(), Materiali(), Lavorazioni()), "xl/worksheets/sheet2.xml",
            [["R", "", "Prodotto finito", "R", "Radice", "1", "10", "Sì", ""]]);
        file = ModificaFoglio(file, doc => doc.Descendants(Spreadsheet + "row").ElementAt(1).Elements(Spreadsheet + "c").First().Add(new XElement(Spreadsheet + "f", "1+1")));
        var analisi = excel.Analizza(file, Tipi(), Materiali(), Lavorazioni());
        Assert.False(analisi.Valida); Assert.Contains(analisi.Errori, x => x.Messaggio.Contains("formula"));
    }

    private static byte[] ModificaFoglio(byte[] file, Action<XDocument> modifica)
    {
        using var output = new MemoryStream(); output.Write(file);
        using (var zip = new ZipArchive(output, ZipArchiveMode.Update, true))
        {
            const string percorso = "xl/worksheets/sheet2.xml";
            var documento = CaricaXml(zip, percorso); modifica(documento);
            zip.GetEntry(percorso)!.Delete(); using var stream = zip.CreateEntry(percorso).Open(); documento.Save(stream);
        }
        return output.ToArray();
    }

    private static IReadOnlyList<TipoNodoDistintaLookupItem> Tipi() =>
    [
        new() { IdTipoNodo = 1, Descrizione = "Prodotto finito", Attivo = true },
        new() { IdTipoNodo = 2, Descrizione = "Componente", Attivo = true }
    ];

    private static IReadOnlyList<DistintaMaterialeLookupItem> Materiali() =>
    [
        new() { IdMateriale = 1, CodiceMateriale = "MAT-01", Descrizione = "Materiale", CodiceUM = "PZ", CostoUnitario = 4.25m }
    ];

    private static IReadOnlyList<DistintaLavorazioneLookupItem> Lavorazioni() =>
    [
        new() { IdLavorazione = 1, CodiceLavorazione = "LAV-01", Descrizione = "Lavorazione", TempoSetupMinDefault = 5, TempoPezzoMinDefault = 0.25m, CostoOrarioStandard = 35 }
    ];

    private static byte[] AggiungiRighe(byte[] contenuto, string percorso, IReadOnlyList<IReadOnlyList<string>> righe)
    {
        using var stream = new MemoryStream();
        stream.Write(contenuto);
        using (var archivio = new ZipArchive(stream, ZipArchiveMode.Update, leaveOpen: true))
        {
            var entry = archivio.GetEntry(percorso)!;
            XDocument documento;
            using (var input = entry.Open()) documento = XDocument.Load(input);
            var sheetData = documento.Descendants(Spreadsheet + "sheetData").Single();
            var rigaCorrente = sheetData.Elements(Spreadsheet + "row").Count() + 1;
            foreach (var valori in righe)
            {
                sheetData.Add(new XElement(Spreadsheet + "row",
                    new XAttribute("r", rigaCorrente),
                    valori.Select((valore, indice) => (Valore: valore, Indice: indice))
                        .Where(cella => !string.IsNullOrEmpty(cella.Valore))
                        .Select(cella => new XElement(Spreadsheet + "c",
                        new XAttribute("r", $"{Colonna(cella.Indice)}{rigaCorrente}"),
                        new XAttribute("t", "inlineStr"),
                        new XElement(Spreadsheet + "is", new XElement(Spreadsheet + "t", cella.Valore))))));
                rigaCorrente++;
            }
            entry.Delete();
            var nuovaEntry = archivio.CreateEntry(percorso, CompressionLevel.Optimal);
            using var output = nuovaEntry.Open();
            documento.Save(output);
        }
        return stream.ToArray();
    }

    private static XDocument CaricaXml(ZipArchive archivio, string percorso)
    {
        using var stream = archivio.GetEntry(percorso)!.Open();
        return XDocument.Load(stream);
    }

    private static string Colonna(int indice)
    {
        var risultato = string.Empty;
        for (var valore = indice + 1; valore > 0; valore = (valore - 1) / 26)
            risultato = (char)('A' + ((valore - 1) % 26)) + risultato;
        return risultato;
    }
}

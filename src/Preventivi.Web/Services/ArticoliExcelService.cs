using System.IO.Compression;
using System.Security.Cryptography;
using System.Xml;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Services;

public sealed class ArticoliExcelAnalisi
{
    public IReadOnlyList<ArticoloImportazioneRiga> Righe { get; init; } = [];
    public IReadOnlyList<ArticoliImportazioneErrore> Errori { get; init; } = [];
    public bool Valida => Righe.Count > 0 && Errori.Count == 0;
}

public sealed class ArticoliExcelService
{
    public const int DimensioneMassimaFile = 2 * 1024 * 1024;
    private static readonly XNamespace Spreadsheet = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
    private static readonly XNamespace OfficeRelations = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
    private static readonly XNamespace PackageRelations = "http://schemas.openxmlformats.org/package/2006/relationships";
    private static readonly string[] Colonne = ["Codice articolo", "Descrizione", "Versione articolo", "Codice cliente", "Note tecniche"];

    public byte[] CreaModello(IReadOnlyList<ClienteAnagraficaLookupItem> clienti)
    {
        var fogli = new List<(string Nome, IReadOnlyList<IReadOnlyList<string>> Righe)>
        {
            ("Istruzioni", [
                ["IMPORTAZIONE NUOVI ARTICOLI"],
                ["Compilare il foglio Articoli. Codice articolo (50 caratteri) e Descrizione (200) sono obbligatori."],
                ["Versione articolo (20), Codice cliente (30) e Note tecniche sono facoltativi."],
                ["Scrivere codici e versioni come testo per conservare gli zeri iniziali."],
                ["I clienti indicati devono esistere ed essere attivi. Consultare Clienti disponibili."],
                ["Non vengono aggiornati o riattivati articoli esistenti, ne creati clienti, distinte o allegati."],
                ["Gli articoli nuovi sono attivi. Codici duplicati o errori bloccano tutto il file."],
                ["Anteprima senza scritture; applicazione solo dopo conferma, in un'unica transazione."],
                ["Sono accettati file .xlsx fino a 2 MB. Non usare formule."]
            ]),
            ("Articoli", [Colonne]),
            ("Clienti disponibili", [
                ["Codice cliente", "Ragione sociale"],
                .. clienti.Where(x => x.Attivo).OrderBy(x => x.CodiceCliente)
                    .Select(x => (IReadOnlyList<string>)[x.CodiceCliente, x.RagioneSociale])
            ])
        };
        using var output = new MemoryStream();
        using (var archivio = new ZipArchive(output, ZipArchiveMode.Create, true))
        {
            Scrivi(archivio, "[Content_Types].xml", CreaContentTypes(fogli.Count));
            Scrivi(archivio, "_rels/.rels", CreaRootRelationships());
            Scrivi(archivio, "xl/workbook.xml", CreaWorkbook(fogli));
            Scrivi(archivio, "xl/_rels/workbook.xml.rels", CreaWorkbookRelationships(fogli.Count));
            Scrivi(archivio, "xl/styles.xml", CreaStyles());
            for (var i = 0; i < fogli.Count; i++) Scrivi(archivio, $"xl/worksheets/sheet{i + 1}.xml", CreaWorksheet(fogli[i].Righe));
        }
        return output.ToArray();
    }

    public static string CalcolaImpronta(byte[] contenuto) => Convert.ToHexString(SHA256.HashData(contenuto));

    public ArticoliExcelAnalisi Analizza(byte[] contenuto)
    {
        var errori = new List<ArticoliImportazioneErrore>();
        var righe = new List<ArticoloImportazioneRiga>();
        if (contenuto.Length == 0 || contenuto.Length > DimensioneMassimaFile)
            return new() { Errori = [new("Articoli", 0, "File", "Selezionare un file .xlsx non vuoto, fino a 2 MB.")] };
        try
        {
            using var archivio = new ZipArchive(new MemoryStream(contenuto, false), ZipArchiveMode.Read);
            if (archivio.Entries.Sum(x => x.Length) > 32 * 1024 * 1024)
                throw new InvalidDataException("Il contenuto decompresso del file e troppo grande.");
            var workbook = Xml(archivio, "xl/workbook.xml");
            var fogli = workbook.Descendants(Spreadsheet + "sheet")
                .Where(x => string.Equals((string?)x.Attribute("name"), "Articoli", StringComparison.OrdinalIgnoreCase)).ToArray();
            if (fogli.Length != 1) throw new InvalidDataException("Il file deve contenere un solo foglio denominato Articoli.");
            var relazione = (string?)fogli[0].Attribute(OfficeRelations + "id");
            var relazioni = Xml(archivio, "xl/_rels/workbook.xml.rels");
            var destinazione = relazioni.Descendants(PackageRelations + "Relationship")
                .SingleOrDefault(x => (string?)x.Attribute("Id") == relazione);
            if (destinazione is null || (string?)destinazione.Attribute("TargetMode") == "External")
                throw new InvalidDataException("Il foglio Articoli non e leggibile.");
            var percorso = ((string?)destinazione.Attribute("Target") ?? "").Replace('\\', '/').TrimStart('/');
            if (!percorso.StartsWith("xl/", StringComparison.OrdinalIgnoreCase)) percorso = "xl/" + percorso;
            var condivise = archivio.GetEntry("xl/sharedStrings.xml") is null ? [] :
                Xml(archivio, "xl/sharedStrings.xml").Descendants(Spreadsheet + "si")
                    .Select(x => string.Concat(x.Descendants(Spreadsheet + "t").Select(t => t.Value))).ToArray();
            var rows = Xml(archivio, percorso).Descendants(Spreadsheet + "row").ToArray();
            if (rows.Length == 0) throw new InvalidDataException("Manca la riga di intestazione.");
            var intestazioni = new Dictionary<int, string>();
            foreach (var c in rows[0].Elements(Spreadsheet + "c"))
            {
                var nome = Valore(c, condivise).Trim();
                if (nome.Length == 0) continue;
                var indice = Indice((string?)c.Attribute("r"));
                if (indice < 0 || intestazioni.ContainsKey(indice) || intestazioni.Values.Contains(nome, StringComparer.OrdinalIgnoreCase))
                    throw new InvalidDataException("Intestazioni duplicate o riferimenti di colonna non validi.");
                if (!Colonne.Contains(nome, StringComparer.OrdinalIgnoreCase))
                    errori.Add(new("Articoli", 1, nome, "Colonna non prevista dal modello Articoli."));
                intestazioni.Add(indice, nome);
            }
            foreach (var richiesto in Colonne.Take(2))
                if (!intestazioni.Values.Contains(richiesto, StringComparer.OrdinalIgnoreCase))
                    errori.Add(new("Articoli", 1, richiesto, "Colonna obbligatoria mancante."));
            foreach (var row in rows.Skip(1))
            {
                var numero = int.TryParse((string?)row.Attribute("r"), out var n) ? n : Array.IndexOf(rows, row) + 1;
                var valori = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (var cella in row.Elements(Spreadsheet + "c"))
                {
                    var valore = Valore(cella, condivise).Trim();
                    var indice = Indice((string?)cella.Attribute("r"));
                    if (!intestazioni.TryGetValue(indice, out var campo))
                    {
                        if (valore.Length > 0) errori.Add(new("Articoli", numero, "Colonna", "Una cella compilata non ha intestazione."));
                        continue;
                    }
                    if (!valori.TryAdd(campo, valore)) errori.Add(new("Articoli", numero, campo, "Cella duplicata nella riga."));
                    if (cella.Element(Spreadsheet + "f") is not null)
                        errori.Add(new("Articoli", numero, campo, "Sostituire la formula con un valore testuale."));
                }
                if (valori.Values.All(string.IsNullOrWhiteSpace)) continue;
                string Testo(string nome) => valori.GetValueOrDefault(nome, "");
                string? Facoltativo(string nome) => string.IsNullOrWhiteSpace(Testo(nome)) ? null : Testo(nome);
                righe.Add(new(numero, Testo("Codice articolo"), Testo("Descrizione"), Facoltativo("Versione articolo"), Facoltativo("Codice cliente"), Facoltativo("Note tecniche")));
            }
            if (righe.Count == 0) errori.Add(new("Articoli", 0, "Righe", "Il file non contiene articoli da importare."));
        }
        catch (Exception e) when (e is InvalidDataException or XmlException or ArgumentException or InvalidOperationException or OverflowException)
        {
            errori.Add(new("Articoli", 0, "File", e is InvalidDataException ? e.Message : "Il file Excel non e valido. Scaricare e compilare il modello."));
        }
        return new() { Righe = righe, Errori = errori };
    }

    private static XDocument Xml(ZipArchive archivio, string percorso)
    {
        using var stream = (archivio.GetEntry(percorso) ?? throw new InvalidDataException("Parte Excel mancante: " + percorso)).Open();
        using var reader = XmlReader.Create(stream, new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, MaxCharactersInDocument = 32 * 1024 * 1024 });
        return XDocument.Load(reader);
    }
    private static string Valore(XElement cella, IReadOnlyList<string> condivise)
    {
        var tipo = (string?)cella.Attribute("t");
        if (tipo == "inlineStr") return string.Concat(cella.Descendants(Spreadsheet + "t").Select(x => x.Value));
        var valore = cella.Element(Spreadsheet + "v")?.Value ?? "";
        if (tipo == "s")
        {
            if (!int.TryParse(valore, out var i) || i < 0 || i >= condivise.Count) throw new InvalidDataException("Indice di testo condiviso non valido.");
            return condivise[i];
        }
        if (tipo == "e") throw new InvalidDataException("Il foglio contiene una cella con errore Excel.");
        return valore;
    }
    private static int Indice(string? riferimento)
    {
        if (string.IsNullOrWhiteSpace(riferimento)) return -1;
        var indice = 0;
        foreach (var c in riferimento.TakeWhile(char.IsLetter)) indice = checked(indice * 26 + char.ToUpperInvariant(c) - 'A' + 1);
        return indice - 1;
    }
    private static void Scrivi(ZipArchive archivio, string percorso, XDocument documento)
    {
        var entry = archivio.CreateEntry(percorso, CompressionLevel.Optimal);
        using var stream = entry.Open();
        documento.Save(stream);
    }

    private static XDocument CreaContentTypes(int numeroFogli)
    {
        XNamespace ns = "http://schemas.openxmlformats.org/package/2006/content-types";
        return new XDocument(new XElement(ns + "Types",
            new XElement(ns + "Default", new XAttribute("Extension", "rels"), new XAttribute("ContentType", "application/vnd.openxmlformats-package.relationships+xml")),
            new XElement(ns + "Default", new XAttribute("Extension", "xml"), new XAttribute("ContentType", "application/xml")),
            new XElement(ns + "Override", new XAttribute("PartName", "/xl/workbook.xml"), new XAttribute("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml")),
            new XElement(ns + "Override", new XAttribute("PartName", "/xl/styles.xml"), new XAttribute("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml")),
            Enumerable.Range(1, numeroFogli).Select(i => new XElement(ns + "Override", new XAttribute("PartName", $"/xl/worksheets/sheet{i}.xml"), new XAttribute("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml")))));
    }

    private static XDocument CreaRootRelationships() =>
        new(new XElement(PackageRelations + "Relationships",
            new XElement(PackageRelations + "Relationship", new XAttribute("Id", "rId1"), new XAttribute("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"), new XAttribute("Target", "xl/workbook.xml"))));

    private static XDocument CreaWorkbook(IReadOnlyList<(string Nome, IReadOnlyList<IReadOnlyList<string>> Righe)> fogli) =>
        new(new XElement(Spreadsheet + "workbook",
            new XAttribute(XNamespace.Xmlns + "r", OfficeRelations),
            new XElement(Spreadsheet + "sheets", fogli.Select((x, i) => new XElement(Spreadsheet + "sheet", new XAttribute("name", x.Nome), new XAttribute("sheetId", i + 1), new XAttribute(OfficeRelations + "id", $"rId{i + 1}"))))));

    private static XDocument CreaWorkbookRelationships(int numeroFogli) =>
        new(new XElement(PackageRelations + "Relationships",
            Enumerable.Range(1, numeroFogli).Select(i => new XElement(PackageRelations + "Relationship", new XAttribute("Id", $"rId{i}"), new XAttribute("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"), new XAttribute("Target", $"worksheets/sheet{i}.xml"))),
            new XElement(PackageRelations + "Relationship", new XAttribute("Id", $"rId{numeroFogli + 1}"), new XAttribute("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"), new XAttribute("Target", "styles.xml"))));

    private static XDocument CreaStyles() =>
        new(new XElement(Spreadsheet + "styleSheet",
            new XElement(Spreadsheet + "fonts", new XAttribute("count", 2),
                new XElement(Spreadsheet + "font", new XElement(Spreadsheet + "sz", new XAttribute("val", 11)), new XElement(Spreadsheet + "name", new XAttribute("val", "Calibri"))),
                new XElement(Spreadsheet + "font", new XElement(Spreadsheet + "b"), new XElement(Spreadsheet + "color", new XAttribute("rgb", "FFFFFFFF")), new XElement(Spreadsheet + "sz", new XAttribute("val", 11)), new XElement(Spreadsheet + "name", new XAttribute("val", "Calibri")))),
            new XElement(Spreadsheet + "fills", new XAttribute("count", 3),
                new XElement(Spreadsheet + "fill", new XElement(Spreadsheet + "patternFill", new XAttribute("patternType", "none"))),
                new XElement(Spreadsheet + "fill", new XElement(Spreadsheet + "patternFill", new XAttribute("patternType", "gray125"))),
                new XElement(Spreadsheet + "fill", new XElement(Spreadsheet + "patternFill", new XAttribute("patternType", "solid"), new XElement(Spreadsheet + "fgColor", new XAttribute("rgb", "FF1F5E92")), new XElement(Spreadsheet + "bgColor", new XAttribute("indexed", 64))))),
            new XElement(Spreadsheet + "borders", new XAttribute("count", 1), new XElement(Spreadsheet + "border", new XElement(Spreadsheet + "left"), new XElement(Spreadsheet + "right"), new XElement(Spreadsheet + "top"), new XElement(Spreadsheet + "bottom"), new XElement(Spreadsheet + "diagonal"))),
            new XElement(Spreadsheet + "cellStyleXfs", new XAttribute("count", 1), new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 49), new XAttribute("fontId", 0), new XAttribute("fillId", 0), new XAttribute("borderId", 0))),
            new XElement(Spreadsheet + "cellXfs", new XAttribute("count", 2),
                new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 49), new XAttribute("fontId", 0), new XAttribute("fillId", 0), new XAttribute("borderId", 0), new XAttribute("xfId", 0)),
                new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 0), new XAttribute("fontId", 1), new XAttribute("fillId", 2), new XAttribute("borderId", 0), new XAttribute("xfId", 0), new XAttribute("applyFont", 1), new XAttribute("applyFill", 1)))));

    private static XDocument CreaWorksheet(IReadOnlyList<IReadOnlyList<string>> righe)
    {
        var sheetData = new XElement(Spreadsheet + "sheetData");
        for (var r = 0; r < righe.Count; r++)
        {
            var row = new XElement(Spreadsheet + "row", new XAttribute("r", r + 1));
            for (var c = 0; c < righe[r].Count; c++)
            {
                row.Add(new XElement(Spreadsheet + "c",
                    new XAttribute("r", $"{NomeColonna(c)}{r + 1}"),
                    new XAttribute("t", "inlineStr"),
                    r == 0 ? new XAttribute("s", 1) : null,
                    new XElement(Spreadsheet + "is", new XElement(Spreadsheet + "t", righe[r][c]))));
            }
            sheetData.Add(row);
        }
        var ultimaColonna = righe.Count == 0 || righe[0].Count == 0 ? "A" : NomeColonna(righe[0].Count - 1);
        return new XDocument(new XElement(Spreadsheet + "worksheet",
            new XElement(Spreadsheet + "sheetViews", new XElement(Spreadsheet + "sheetView", new XAttribute("workbookViewId", 0), new XElement(Spreadsheet + "pane", new XAttribute("ySplit", 1), new XAttribute("topLeftCell", "A2"), new XAttribute("state", "frozen")))),
            new XElement(Spreadsheet + "cols", Enumerable.Range(1, Math.Max(1, righe.FirstOrDefault()?.Count ?? 1)).Select(i => new XElement(Spreadsheet + "col", new XAttribute("min", i), new XAttribute("max", i), new XAttribute("width", i == 1 ? 24 : 20), new XAttribute("customWidth", 1), new XAttribute("style", 0)))),
            sheetData,
            new XElement(Spreadsheet + "autoFilter", new XAttribute("ref", $"A1:{ultimaColonna}1"))));
    }

    private static string NomeColonna(int indice)
    {
        var valore = indice + 1;
        var risultato = string.Empty;
        while (valore > 0)
        {
            valore--;
            risultato = (char)('A' + (valore % 26)) + risultato;
            valore /= 26;
        }
        return risultato;
    }

}

using System.Globalization;
using System.IO.Compression;
using System.Text.Json;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Services;

public sealed partial class DistintaBaseExcelService
{
    private const string FormulaSelezionePadre = "IF(TabellaDistinta[[#This Row],[Codice]]=\"\",\"\",TabellaDistinta[[#This Row],[Codice]]&IF(TabellaDistinta[[#This Row],[Descrizione]]=\"\",\"\",\" - \"&TabellaDistinta[[#This Row],[Descrizione]]))";
    private static readonly string[] ColonneSemplificate =
    [
        "Codice", "Descrizione", "Componente padre", "Tipo componente", "Quantità base",
        "Materiale", "Quantità materiale", "Lavorazione", "Costo materiale", "Setup min",
        "Tempo pezzo min", "Costo orario", "Costo fisso", "Scarto %", "Note componente",
        "Note materiale", "Note lavorazione", "Selezione padre"
    ];

    public byte[] CreaModelloSemplificato(IReadOnlyList<TipoNodoDistintaLookupItem> tipiNodo,
        IReadOnlyList<DistintaMaterialeLookupItem> materiali, IReadOnlyList<DistintaLavorazioneLookupItem> lavorazioni)
    {
        var tipi = tipiNodo.Where(x => x.Attivo).Select(x => x.Descrizione).Order().ToArray();
        var elencoMateriali = materiali.OrderBy(x => x.CodiceMateriale).Select(x => x.Display).ToArray();
        var elencoLavorazioni = lavorazioni.OrderBy(x => x.CodiceLavorazione).Select(x => x.Display).ToArray();
        var supporto = new List<IReadOnlyList<string>> { new[] { "Tipi componente", "Materiali", "Lavorazioni" } };
        for (var i = 0; i < Math.Max(tipi.Length, Math.Max(elencoMateriali.Length, elencoLavorazioni.Length)); i++)
            supporto.Add([tipi.ElementAtOrDefault(i) ?? "", elencoMateriali.ElementAtOrDefault(i) ?? "", elencoLavorazioni.ElementAtOrDefault(i) ?? ""]);
        return CreaCartella([
            ("Istruzioni", new IReadOnlyList<string>[] {
                new[] { "DISTINTA SEMPLIFICATA - UN SOLO FOGLIO DA COMPILARE" },
                new[] { "Compilare il foglio Distinta. La destinazione deve essere una distinta corrente vuota." },
                new[] { "Prima riga del componente: codice breve (es. C01), descrizione, tipo e quantita base." },
                new[] { "Componente padre: selezionare codice e descrizione dal menu; lasciarlo vuoto solo per la radice." },
                new[] { "Materiale e lavorazione si scelgono dai menu. Compilare Quantita materiale quando si sceglie un materiale." },
                new[] { "Per piu materiali/lavorazioni ripetere il codice e compilare solo il nuovo elemento: i dati del componente possono restare vuoti." },
                new[] { "Non ripetere lo stesso materiale sul componente. Righe lavorazione identiche vengono segnalate come ambigue." },
                new[] { "Costi, tempi e note sono nelle colonne facoltative I-Q, espandibili con il pulsante + sopra le colonne." },
                new[] { "Costi e tempi vuoti usano i valori correnti dell'anagrafica nell'anteprima. Lo zero digitato resta zero. Scarto e costo fisso vuoti valgono zero." },
                new[] { "Ordine, livelli, chiavi interne e sequenze lavorazioni sono calcolati automaticamente. I componenti vengono creati attivi." },
                new[] { "Scrivere i codici come testo per conservare gli zeri iniziali. Il modello avanzato resta disponibile per strutture con campi aggiuntivi." },
                new[] { "Supporto contiene solo gli elenchi delle anagrafiche: non modificarlo. Nessun dato viene scritto prima della conferma nell'app." }
            }),
            ("Distinta", new IReadOnlyList<string>[] { ColonneSemplificate, Enumerable.Repeat("", ColonneSemplificate.Length).ToArray() }),
            ("Supporto", supporto)
        ], zip => AggiungiMenuSemplificato(zip, tipi.Length, elencoMateriali.Length, elencoLavorazioni.Length));
    }

    private static void AggiungiMenuSemplificato(ZipArchive zip, int tipi, int materiali, int lavorazioni)
    {
        var workbook = CaricaXml(zip, "xl/workbook.xml");
        workbook.Root!.Add(new XElement(Spreadsheet + "definedNames",
            new XElement(Spreadsheet + "definedName", new XAttribute("name", "ElencoTipiComponente"), $"'Supporto'!$A$2:$A${Math.Max(2, tipi + 1)}"),
            new XElement(Spreadsheet + "definedName", new XAttribute("name", "ElencoMateriali"), $"'Supporto'!$B$2:$B${Math.Max(2, materiali + 1)}"),
            new XElement(Spreadsheet + "definedName", new XAttribute("name", "ElencoLavorazioni"), $"'Supporto'!$C$2:$C${Math.Max(2, lavorazioni + 1)}"),
            new XElement(Spreadsheet + "definedName", new XAttribute("name", "ElencoPadri"), "TabellaDistinta[Selezione padre]")));
        workbook.Root.Add(new XElement(Spreadsheet + "calcPr", new XAttribute("calcId", 191029), new XAttribute("fullCalcOnLoad", 1), new XAttribute("forceFullCalc", 1)));
        SostituisciXml(zip, "xl/workbook.xml", workbook);
        var styles = CaricaXml(zip, "xl/styles.xml");
        var formati = styles.Root!.Element(Spreadsheet + "cellXfs")!;
        var indiceTesto = formati.Elements().Count();
        formati.Add(new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 49), new XAttribute("fontId", 0), new XAttribute("fillId", 0), new XAttribute("borderId", 0), new XAttribute("xfId", 0), new XAttribute("applyNumberFormat", 1)));
        formati.SetAttributeValue("count", indiceTesto + 1);
        SostituisciXml(zip, "xl/styles.xml", styles);

        var sheet = CaricaXml(zip, "xl/worksheets/sheet2.xml");
        sheet.Root!.Element(Spreadsheet + "autoFilter")?.Remove();
        var cols = sheet.Root.Element(Spreadsheet + "cols")!.Elements().ToArray();
        cols[0].SetAttributeValue("style", indiceTesto);
        cols[1].SetAttributeValue("width", 32); cols[2].SetAttributeValue("width", 30);
        cols[5].SetAttributeValue("width", 32); cols[7].SetAttributeValue("width", 32);
        foreach (var col in cols.Skip(8).Take(9)) { col.SetAttributeValue("hidden", 1); col.SetAttributeValue("outlineLevel", 1); }
        cols[17].SetAttributeValue("hidden", 1); cols[17].SetAttributeValue("collapsed", 1);
        sheet.Root.Element(Spreadsheet + "sheetViews")!.AddAfterSelf(new XElement(Spreadsheet + "sheetFormatPr", new XAttribute("defaultRowHeight", 15), new XAttribute("outlineLevelCol", 1)));
        sheet.Descendants(Spreadsheet + "c").Single(x => (string?)x.Attribute("r") == "R2").ReplaceWith(
            new XElement(Spreadsheet + "c", new XAttribute("r", "R2"), new XElement(Spreadsheet + "f", FormulaSelezionePadre)));
        XElement Menu(string colonna, string nome) => new(Spreadsheet + "dataValidation",
            new XAttribute("type", "list"), new XAttribute("allowBlank", 1), new XAttribute("showErrorMessage", 1),
            new XAttribute("errorStyle", "stop"), new XAttribute("errorTitle", "Selezione non valida"),
            new XAttribute("error", "Selezionare una voce dal menu a tendina."), new XAttribute("sqref", $"{colonna}2:{colonna}1048576"),
            new XElement(Spreadsheet + "formula1", nome));
        sheet.Root.Add(new XElement(Spreadsheet + "dataValidations", new XAttribute("count", 4),
            Menu("C", "ElencoPadri"), Menu("D", "ElencoTipiComponente"), Menu("F", "ElencoMateriali"), Menu("H", "ElencoLavorazioni")));
        sheet.Root.Add(new XElement(Spreadsheet + "tableParts", new XAttribute("count", 1), new XElement(Spreadsheet + "tablePart", new XAttribute(OfficeRelations + "id", "rIdTabellaDistinta"))));
        SostituisciXml(zip, "xl/worksheets/sheet2.xml", sheet);
        Scrivi(zip, "xl/worksheets/_rels/sheet2.xml.rels", new XDocument(new XElement(PackageRelations + "Relationships",
            new XElement(PackageRelations + "Relationship", new XAttribute("Id", "rIdTabellaDistinta"), new XAttribute("Type", "http://schemas.openxmlformats.org/officeDocument/2006/relationships/table"), new XAttribute("Target", "../tables/table1.xml")))));
        var colonne = ColonneSemplificate.Select((nome, i) => new XElement(Spreadsheet + "tableColumn", new XAttribute("id", i + 1), new XAttribute("name", nome),
            i == 17 ? new XElement(Spreadsheet + "calculatedColumnFormula", FormulaSelezionePadre) : null));
        Scrivi(zip, "xl/tables/table1.xml", new XDocument(new XElement(Spreadsheet + "table",
            new XAttribute("id", 1), new XAttribute("name", "TabellaDistinta"), new XAttribute("displayName", "TabellaDistinta"), new XAttribute("ref", "A1:R2"), new XAttribute("totalsRowShown", 0),
            new XElement(Spreadsheet + "autoFilter", new XAttribute("ref", "A1:R2")),
            new XElement(Spreadsheet + "tableColumns", new XAttribute("count", 18), colonne),
            new XElement(Spreadsheet + "tableStyleInfo", new XAttribute("name", "TableStyleMedium2"), new XAttribute("showFirstColumn", 0), new XAttribute("showLastColumn", 0), new XAttribute("showRowStripes", 1), new XAttribute("showColumnStripes", 0)))));
        var contentTypes = CaricaXml(zip, "[Content_Types].xml");
        contentTypes.Root!.Add(new XElement(contentTypes.Root.Name.Namespace + "Override", new XAttribute("PartName", "/xl/tables/table1.xml"), new XAttribute("ContentType", "application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml")));
        SostituisciXml(zip, "[Content_Types].xml", contentTypes);
    }

    private static void SostituisciXml(ZipArchive zip, string percorso, XDocument documento)
    { zip.GetEntry(percorso)?.Delete(); Scrivi(zip, percorso, documento); }

    public static string CalcolaImprontaAnalisi(DistintaImportazioneAnalisi analisi) =>
        CalcolaImpronta(JsonSerializer.SerializeToUtf8Bytes(new { analisi.Nodi, analisi.Materiali, analisi.Lavorazioni }));

    private static DistintaImportazioneAnalisi AnalizzaSemplificato(IReadOnlyList<Dictionary<string, string>> righe,
        IReadOnlyList<TipoNodoDistintaLookupItem> tipi, IReadOnlyList<DistintaMaterialeLookupItem> materiali,
        IReadOnlyList<DistintaLavorazioneLookupItem> lavorazioni, List<DistintaImportazioneErrore> errori)
    {
        var nodi = new List<DistintaImportazioneNodo>();
        var righeMateriali = new List<DistintaImportazioneMateriale>();
        var righeLavorazioni = new List<DistintaImportazioneLavorazione>();
        foreach (var riga in righe.Where(x => string.IsNullOrWhiteSpace(Testo(x, "Codice"))))
            Errore(riga, "Codice", "Indicare il codice del componente anche nelle righe aggiuntive.");
        var gruppi = righe.Where(x => !string.IsNullOrWhiteSpace(Testo(x, "Codice")))
            .GroupBy(x => Testo(x, "Codice"), StringComparer.OrdinalIgnoreCase).ToArray();
        var mappa = gruppi.Select((g, i) => (g.Key, Chiave: "N" + (i + 1)))
            .ToDictionary(x => x.Key, x => x.Chiave, StringComparer.OrdinalIgnoreCase);
        var padri = gruppi.Select(g => (Codice: g.Key, Display: g.Key + " - " + Testo(g.First(), "Descrizione"))).ToArray();
        foreach (var gruppo in gruppi)
        {
            var prima = gruppo.First(); var chiave = mappa[gruppo.Key];
            Richiesto("Distinta", Riga(prima), "Codice", gruppo.Key, 50, errori);
            var padre = Risolvi(prima, "Componente padre", padri, false);
            var quantita = Decimale(prima, "Quantità base", "Distinta", Riga(prima), errori);
            var note = gruppo.Select(x => TestoNull(x, "Note componente")).FirstOrDefault(x => x is not null);
            nodi.Add(new() { RigaExcel = Riga(prima), ChiaveNodo = chiave, ChiavePadre = padre is null ? null : mappa.GetValueOrDefault(padre),
                CodiceNodo = gruppo.Key, DescrizioneNodo = Testo(prima, "Descrizione"), TipoNodo = Testo(prima, "Tipo componente"),
                QuantitaBase = quantita, OrdineVisualizzazione = nodi.Count * 10 + 10, Attivo = true, Note = note });
            var sequenza = 0;
            var firmeLavorazioni = new HashSet<string>(StringComparer.Ordinal);
            foreach (var riga in gruppo)
            {
                if (!ReferenceEquals(riga, prima))
                {
                    Coerente("Descrizione", Testo(prima, "Descrizione"));
                    Coerente("Tipo componente", Testo(prima, "Tipo componente"));
                    if (Testo(riga, "Componente padre").Length > 0 && !string.Equals(Risolvi(riga, "Componente padre", padri, false), padre, StringComparison.OrdinalIgnoreCase))
                        Errore(riga, "Componente padre", "Il padre non coincide con la prima riga del componente.");
                    if (Testo(riga, "Quantità base").Length > 0 && Decimale(riga, "Quantità base", "Distinta", Riga(riga), errori) != quantita)
                        Errore(riga, "Quantità base", "La quantita non coincide con la prima riga del componente.");
                    if (Testo(riga, "Materiale").Length == 0 && Testo(riga, "Lavorazione").Length == 0)
                        Errore(riga, "Codice", "Riga ripetuta senza un nuovo materiale o una nuova lavorazione.");
                }
                if (Testo(riga, "Note componente").Length > 0 && Testo(riga, "Note componente") != note)
                    Errore(riga, "Note componente", "Note componente incoerenti fra le righe dello stesso codice.");
                var codiceMateriale = Risolvi(riga, "Materiale", materiali.Select(x => (x.CodiceMateriale, x.Display)), false);
                if (codiceMateriale is not null)
                {
                    var anagrafica = materiali.First(x => string.Equals(x.CodiceMateriale, codiceMateriale, StringComparison.OrdinalIgnoreCase));
                    righeMateriali.Add(new() { RigaExcel = Riga(riga), ChiaveNodo = chiave, CodiceMateriale = anagrafica.CodiceMateriale,
                        Quantita = Decimale(riga, "Quantità materiale", "Distinta", Riga(riga), errori),
                        CostoUnitario = Facoltativo("Costo materiale", anagrafica.CostoUnitario), CoeffScartoPerc = Facoltativo("Scarto %", 0), Note = TestoNull(riga, "Note materiale") });
                }
                else if (Testo(riga, "Materiale").Length == 0 && new[] { "Quantità materiale", "Costo materiale", "Scarto %", "Note materiale" }.Any(c => Testo(riga, c).Length > 0))
                    Errore(riga, "Materiale", "Selezionare il materiale per compilare quantita, costo, scarto o note materiale.");
                var codiceLavorazione = Risolvi(riga, "Lavorazione", lavorazioni.Select(x => (x.CodiceLavorazione, x.Display)), false);
                if (codiceLavorazione is not null)
                {
                    var anagrafica = lavorazioni.First(x => string.Equals(x.CodiceLavorazione, codiceLavorazione, StringComparison.OrdinalIgnoreCase));
                    var setup = Facoltativo("Setup min", anagrafica.TempoSetupMinDefault);
                    var pezzo = Facoltativo("Tempo pezzo min", anagrafica.TempoPezzoMinDefault);
                    var orario = Facoltativo("Costo orario", anagrafica.CostoOrarioStandard);
                    var fisso = Facoltativo("Costo fisso", 0);
                    var nota = TestoNull(riga, "Note lavorazione");
                    var firma = JsonSerializer.Serialize(new { anagrafica.CodiceLavorazione, setup, pezzo, orario, fisso, nota });
                    if (!firmeLavorazioni.Add(firma)) Errore(riga, "Lavorazione", "Lavorazione identica ripetuta sul componente: specificare una fase distinta o rimuovere la ripetizione.");
                    righeLavorazioni.Add(new() { RigaExcel = Riga(riga), ChiaveNodo = chiave, CodiceLavorazione = anagrafica.CodiceLavorazione,
                        Sequenza = ++sequenza * 10, TempoSetupMin = setup, TempoPezzoMin = pezzo, CostoOrario = orario, CostoFisso = fisso, Note = nota });
                }
                else if (Testo(riga, "Lavorazione").Length == 0 && new[] { "Setup min", "Tempo pezzo min", "Costo orario", "Costo fisso", "Note lavorazione" }.Any(c => Testo(riga, c).Length > 0))
                    Errore(riga, "Lavorazione", "Selezionare la lavorazione per compilare tempi, costi o note lavorazione.");

                void Coerente(string campo, string valore)
                { if (Testo(riga, campo).Length > 0 && !string.Equals(Testo(riga, campo), valore, StringComparison.OrdinalIgnoreCase)) Errore(riga, campo, "Dato diverso dalla prima riga dello stesso componente."); }
                decimal Facoltativo(string campo, decimal valore) => Testo(riga, campo).Length == 0 ? valore : Decimale(riga, campo, "Distinta", Riga(riga), errori);
            }
        }
        var controlli = new List<DistintaImportazioneErrore>();
        Valida(nodi, righeMateriali, righeLavorazioni, tipi, materiali, lavorazioni, controlli);
        foreach (var e in controlli)
        {
            var campo = e.Campo switch
            {
                "Chiave nodo" => "Codice", "Chiave padre" => "Componente padre", "Tipo nodo" => "Tipo componente", "Descrizione nodo" => "Descrizione",
                "Codice materiale" => "Materiale", "Codice lavorazione" => "Lavorazione", "Quantità" => "Quantità materiale",
                "Tempo setup min" => "Setup min", "Costo unitario" => "Costo materiale",
                "Note" => e.Foglio == "Nodi" ? "Note componente" : e.Foglio == "Materiali" ? "Note materiale" : "Note lavorazione",
                _ => e.Campo
            };
            errori.Add(new("Distinta", e.Riga, campo, e.Messaggio.Replace("Chiave padre", "Componente padre").Replace("chiave padre", "componente padre")));
        }
        return new() { Nodi = nodi, Materiali = righeMateriali, Lavorazioni = righeLavorazioni, Errori = errori, ModelloSemplificato = true };

        void Errore(IReadOnlyDictionary<string, string> riga, string campo, string testo) => errori.Add(new("Distinta", Riga(riga), campo, testo));
        string? Risolvi(IReadOnlyDictionary<string, string> riga, string campo, IEnumerable<(string Codice, string Display)> sorgente, bool richiesto)
        {
            var testo = Testo(riga, campo);
            if (testo.Length == 0) { if (richiesto) Errore(riga, campo, "Selezionare una voce."); return null; }
            var voci = sorgente.ToArray();
            var candidati = voci.Where(x => string.Equals(x.Codice, testo, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (candidati.Length == 0) candidati = voci.Where(x => string.Equals(x.Display, testo, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (candidati.Length == 0) candidati = voci.Where(x => testo.StartsWith(x.Codice + " - ", StringComparison.OrdinalIgnoreCase)).ToArray();
            if (candidati.Length == 1) return candidati[0].Codice;
            Errore(riga, campo, candidati.Length > 1 ? "Selezione ambigua: usare un codice univoco." : "La voce selezionata non esiste o non e piu disponibile.");
            return null;
        }
    }
}

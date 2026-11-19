using System.Globalization;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Xml.Linq;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Services;

public sealed record DistintaImportazioneErrore(
    string Foglio,
    int Riga,
    string Campo,
    string Messaggio);

public sealed class DistintaImportazioneAnalisi
{
    public IReadOnlyList<DistintaImportazioneNodo> Nodi { get; init; } = [];
    public IReadOnlyList<DistintaImportazioneMateriale> Materiali { get; init; } = [];
    public IReadOnlyList<DistintaImportazioneLavorazione> Lavorazioni { get; init; } = [];
    public IReadOnlyList<DistintaImportazioneErrore> Errori { get; init; } = [];
    public bool Valida => Errori.Count == 0 && Nodi.Count > 0;
}

public sealed class DistintaBaseExcelService
{
    public const int DimensioneMassimaFile = 2 * 1024 * 1024;

    private static readonly CultureInfo CulturaItaliana = CultureInfo.GetCultureInfo("it-IT");
    private static readonly CultureInfo CulturaInvariante = CultureInfo.InvariantCulture;
    private static readonly XNamespace Spreadsheet = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
    private static readonly XNamespace OfficeRelations = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
    private static readonly XNamespace PackageRelations = "http://schemas.openxmlformats.org/package/2006/relationships";

    private static readonly string[] ColonneNodi =
    [
        "Chiave nodo", "Chiave padre", "Tipo nodo", "Codice nodo",
        "Descrizione nodo", "Quantità base", "Ordine", "Attivo", "Note"
    ];

    private static readonly string[] ColonneMateriali =
    [
        "Chiave nodo", "Codice materiale", "Quantità", "Scarto %",
        "Costo unitario", "Note"
    ];

    private static readonly string[] ColonneLavorazioni =
    [
        "Chiave nodo", "Codice lavorazione", "Sequenza", "Tempo setup min",
        "Tempo pezzo min", "Costo orario", "Costo fisso", "Note"
    ];

    public byte[] CreaModello(
        IReadOnlyList<TipoNodoDistintaLookupItem> tipiNodo,
        IReadOnlyList<DistintaMaterialeLookupItem> materiali,
        IReadOnlyList<DistintaLavorazioneLookupItem> lavorazioni)
    {
        var fogli = new List<(string Nome, IReadOnlyList<IReadOnlyList<string>> Righe)>
        {
            ("Istruzioni", CreaIstruzioni()),
            ("Nodi", [ColonneNodi]),
            ("Materiali", [ColonneMateriali]),
            ("Lavorazioni", [ColonneLavorazioni]),
            ("Tipi nodo", [
                ["Tipo nodo ammesso"],
                .. tipiNodo.Where(x => x.Attivo).OrderBy(x => x.Descrizione).Select(x => (IReadOnlyList<string>)[x.Descrizione])
            ]),
            ("Anagrafica materiali", [
                ["Codice materiale", "Descrizione", "UM", "Costo unitario"],
                .. materiali.OrderBy(x => x.CodiceMateriale).Select(x => (IReadOnlyList<string>)[x.CodiceMateriale, x.Descrizione, x.CodiceUM, Numero(x.CostoUnitario)])
            ]),
            ("Anagrafica lavorazioni", [
                ["Codice lavorazione", "Descrizione", "Setup min", "Tempo pezzo min", "Costo orario"],
                .. lavorazioni.OrderBy(x => x.CodiceLavorazione).Select(x => (IReadOnlyList<string>)[x.CodiceLavorazione, x.Descrizione, Numero(x.TempoSetupMinDefault), Numero(x.TempoPezzoMinDefault), Numero(x.CostoOrarioStandard)])
            ])
        };

        using var output = new MemoryStream();
        using (var archivio = new ZipArchive(output, ZipArchiveMode.Create, leaveOpen: true))
        {
            Scrivi(archivio, "[Content_Types].xml", CreaContentTypes(fogli.Count));
            Scrivi(archivio, "_rels/.rels", CreaRootRelationships());
            Scrivi(archivio, "xl/workbook.xml", CreaWorkbook(fogli));
            Scrivi(archivio, "xl/_rels/workbook.xml.rels", CreaWorkbookRelationships(fogli.Count));
            Scrivi(archivio, "xl/styles.xml", CreaStyles());
            for (var indice = 0; indice < fogli.Count; indice++)
            {
                Scrivi(
                    archivio,
                    $"xl/worksheets/sheet{indice + 1}.xml",
                    CreaWorksheet(fogli[indice].Righe));
            }
        }
        return output.ToArray();
    }

    public DistintaImportazioneAnalisi Analizza(
        byte[] contenuto,
        IReadOnlyList<TipoNodoDistintaLookupItem> tipiNodo,
        IReadOnlyList<DistintaMaterialeLookupItem> materiali,
        IReadOnlyList<DistintaLavorazioneLookupItem> lavorazioni)
    {
        ArgumentNullException.ThrowIfNull(contenuto);
        var errori = new List<DistintaImportazioneErrore>();
        if (contenuto.Length == 0 || contenuto.Length > DimensioneMassimaFile)
        {
            errori.Add(new("File", 0, "File", $"Il file deve avere dimensione compresa fra 1 byte e {DimensioneMassimaFile / 1024 / 1024} MB."));
            return new DistintaImportazioneAnalisi { Errori = errori };
        }

        Dictionary<string, IReadOnlyList<Dictionary<string, string>>> fogli;
        try
        {
            fogli = LeggiFogli(contenuto, errori);
        }
        catch (InvalidDataException)
        {
            errori.Add(new("File", 0, "File", "Il file non è un documento Excel .xlsx valido."));
            return new DistintaImportazioneAnalisi { Errori = errori };
        }
        catch (System.Xml.XmlException)
        {
            errori.Add(new("File", 0, "File", "La struttura XML del documento Excel non è valida."));
            return new DistintaImportazioneAnalisi { Errori = errori };
        }

        var nodi = LeggiNodi(fogli, errori);
        var righeMateriali = LeggiMateriali(fogli, errori);
        var righeLavorazioni = LeggiLavorazioni(fogli, errori);
        Valida(nodi, righeMateriali, righeLavorazioni, tipiNodo, materiali, lavorazioni, errori);

        return new DistintaImportazioneAnalisi
        {
            Nodi = nodi,
            Materiali = righeMateriali,
            Lavorazioni = righeLavorazioni,
            Errori = errori
        };
    }

    public static string CalcolaImpronta(byte[] contenuto) =>
        Convert.ToHexString(SHA256.HashData(contenuto));

    private static IReadOnlyList<IReadOnlyList<string>> CreaIstruzioni() =>
    [
        ["IMPORTAZIONE MASSIVA DISTINTA BASE"],
        ["Compilare esclusivamente i fogli Nodi, Materiali e Lavorazioni."],
        ["La revisione di destinazione deve essere in bozza e priva di nodi."],
        ["Chiave nodo è un identificativo testuale univoco nel file; Chiave padre richiama la chiave del nodo padre."],
        ["Deve esistere un solo nodo radice, con Chiave padre vuota e stato Attivo = Sì."],
        ["Tipo nodo deve coincidere con una voce del foglio Tipi nodo."],
        ["Materiali e lavorazioni devono usare codici presenti nei rispettivi fogli di anagrafica."],
        ["Valori ammessi per Attivo: Sì, Si, 1, True, Attivo; oppure No, 0, False, Non attivo."],
        ["Gli allegati non vengono importati."],
        ["Il file viene prima validato e mostrato in anteprima; nessun dato è scritto prima della conferma."],
        ["Esempio gerarchia: RADICE (padre vuoto), FIANCO_DX (padre RADICE), FIANCO_SX (padre RADICE)."]
    ];

    private static Dictionary<string, IReadOnlyList<Dictionary<string, string>>> LeggiFogli(
        byte[] contenuto,
        ICollection<DistintaImportazioneErrore> errori)
    {
        using var stream = new MemoryStream(contenuto, writable: false);
        using var archivio = new ZipArchive(stream, ZipArchiveMode.Read);
        var workbook = CaricaXml(archivio, "xl/workbook.xml");
        var relazioni = CaricaXml(archivio, "xl/_rels/workbook.xml.rels")
            .Root!
            .Elements(PackageRelations + "Relationship")
            .ToDictionary(
                x => (string)x.Attribute("Id")!,
                x => NormalizzaPercorsoFoglio((string)x.Attribute("Target")!),
                StringComparer.Ordinal);
        var condivise = LeggiStringheCondivise(archivio);
        var risultato = new Dictionary<string, IReadOnlyList<Dictionary<string, string>>>(StringComparer.OrdinalIgnoreCase);

        foreach (var sheet in workbook.Descendants(Spreadsheet + "sheet"))
        {
            var nome = (string?)sheet.Attribute("name") ?? string.Empty;
            var relationId = (string?)sheet.Attribute(OfficeRelations + "id");
            if (string.IsNullOrWhiteSpace(nome) || relationId is null || !relazioni.TryGetValue(relationId, out var percorso))
            {
                continue;
            }
            risultato[nome] = LeggiRighe(CaricaXml(archivio, percorso), condivise, nome, errori);
        }

        foreach (var obbligatorio in new[] { "Nodi", "Materiali", "Lavorazioni" })
        {
            if (!risultato.ContainsKey(obbligatorio))
            {
                errori.Add(new(obbligatorio, 0, "Foglio", $"Il foglio obbligatorio '{obbligatorio}' non è presente."));
            }
        }
        return risultato;
    }

    private static IReadOnlyList<Dictionary<string, string>> LeggiRighe(
        XDocument worksheet,
        IReadOnlyList<string> condivise,
        string foglio,
        ICollection<DistintaImportazioneErrore> errori)
    {
        var rows = worksheet.Descendants(Spreadsheet + "row").ToArray();
        if (rows.Length == 0)
        {
            errori.Add(new(foglio, 0, "Intestazione", "Il foglio non contiene l'intestazione."));
            return [];
        }

        var intestazioni = rows[0].Elements(Spreadsheet + "c")
            .Select(c => (IndiceColonna((string?)c.Attribute("r")), ValoreCella(c, condivise).Trim()))
            .Where(x => x.Item1 >= 0 && !string.IsNullOrWhiteSpace(x.Item2))
            .ToDictionary(x => x.Item1, x => x.Item2);
        var colonneRichieste = foglio.ToUpperInvariant() switch
        {
            "NODI" => ColonneNodi,
            "MATERIALI" => ColonneMateriali,
            "LAVORAZIONI" => ColonneLavorazioni,
            _ => Array.Empty<string>()
        };
        var nomiColonne = intestazioni.Values.ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var colonna in colonneRichieste.Where(c => !nomiColonne.Contains(c)))
            errori.Add(new(foglio, 1, colonna, $"La colonna obbligatoria '{colonna}' non è presente."));
        var risultato = new List<Dictionary<string, string>>();
        foreach (var row in rows.Skip(1))
        {
            var numero = (int?)row.Attribute("r") ?? 0;
            var valori = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["__RigaExcel"] = numero.ToString(CultureInfo.InvariantCulture)
            };
            foreach (var cella in row.Elements(Spreadsheet + "c"))
            {
                var indice = IndiceColonna((string?)cella.Attribute("r"));
                if (intestazioni.TryGetValue(indice, out var colonna))
                {
                    valori[colonna] = ValoreCella(cella, condivise).Trim();
                }
            }
            if (valori.Any(x => x.Key != "__RigaExcel" && !string.IsNullOrWhiteSpace(x.Value)))
            {
                risultato.Add(valori);
            }
        }
        return risultato;
    }

    private static List<DistintaImportazioneNodo> LeggiNodi(
        IReadOnlyDictionary<string, IReadOnlyList<Dictionary<string, string>>> fogli,
        ICollection<DistintaImportazioneErrore> errori)
    {
        if (!fogli.TryGetValue("Nodi", out var righe)) return [];
        var risultato = new List<DistintaImportazioneNodo>();
        foreach (var riga in righe)
        {
            var numero = Riga(riga);
            risultato.Add(new DistintaImportazioneNodo
            {
                RigaExcel = numero,
                ChiaveNodo = Testo(riga, "Chiave nodo"),
                ChiavePadre = TestoNull(riga, "Chiave padre"),
                TipoNodo = Testo(riga, "Tipo nodo"),
                CodiceNodo = TestoNull(riga, "Codice nodo"),
                DescrizioneNodo = Testo(riga, "Descrizione nodo"),
                QuantitaBase = Decimale(riga, "Quantità base", "Nodi", numero, errori),
                OrdineVisualizzazione = Intero(riga, "Ordine", "Nodi", numero, errori),
                Attivo = Booleano(riga, "Attivo", "Nodi", numero, errori),
                Note = TestoNull(riga, "Note")
            });
        }
        return risultato;
    }

    private static List<DistintaImportazioneMateriale> LeggiMateriali(
        IReadOnlyDictionary<string, IReadOnlyList<Dictionary<string, string>>> fogli,
        ICollection<DistintaImportazioneErrore> errori)
    {
        if (!fogli.TryGetValue("Materiali", out var righe)) return [];
        return righe.Select(riga =>
        {
            var numero = Riga(riga);
            return new DistintaImportazioneMateriale
            {
                RigaExcel = numero,
                ChiaveNodo = Testo(riga, "Chiave nodo"),
                CodiceMateriale = Testo(riga, "Codice materiale"),
                Quantita = Decimale(riga, "Quantità", "Materiali", numero, errori),
                CoeffScartoPerc = Decimale(riga, "Scarto %", "Materiali", numero, errori),
                CostoUnitario = Decimale(riga, "Costo unitario", "Materiali", numero, errori),
                Note = TestoNull(riga, "Note")
            };
        }).ToList();
    }

    private static List<DistintaImportazioneLavorazione> LeggiLavorazioni(
        IReadOnlyDictionary<string, IReadOnlyList<Dictionary<string, string>>> fogli,
        ICollection<DistintaImportazioneErrore> errori)
    {
        if (!fogli.TryGetValue("Lavorazioni", out var righe)) return [];
        return righe.Select(riga =>
        {
            var numero = Riga(riga);
            return new DistintaImportazioneLavorazione
            {
                RigaExcel = numero,
                ChiaveNodo = Testo(riga, "Chiave nodo"),
                CodiceLavorazione = Testo(riga, "Codice lavorazione"),
                Sequenza = Intero(riga, "Sequenza", "Lavorazioni", numero, errori),
                TempoSetupMin = Decimale(riga, "Tempo setup min", "Lavorazioni", numero, errori),
                TempoPezzoMin = Decimale(riga, "Tempo pezzo min", "Lavorazioni", numero, errori),
                CostoOrario = Decimale(riga, "Costo orario", "Lavorazioni", numero, errori),
                CostoFisso = Decimale(riga, "Costo fisso", "Lavorazioni", numero, errori),
                Note = TestoNull(riga, "Note")
            };
        }).ToList();
    }

    private static void Valida(
        IReadOnlyList<DistintaImportazioneNodo> nodi,
        IReadOnlyList<DistintaImportazioneMateriale> materialiImportati,
        IReadOnlyList<DistintaImportazioneLavorazione> lavorazioniImportate,
        IReadOnlyList<TipoNodoDistintaLookupItem> tipiNodo,
        IReadOnlyList<DistintaMaterialeLookupItem> materiali,
        IReadOnlyList<DistintaLavorazioneLookupItem> lavorazioni,
        ICollection<DistintaImportazioneErrore> errori)
    {
        var chiavi = new Dictionary<string, DistintaImportazioneNodo>(StringComparer.OrdinalIgnoreCase);
        var tipiAmmessi = tipiNodo.Where(x => x.Attivo).Select(x => x.Descrizione).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var nodo in nodi)
        {
            Richiesto("Nodi", nodo.RigaExcel, "Chiave nodo", nodo.ChiaveNodo, 50, errori);
            Richiesto("Nodi", nodo.RigaExcel, "Tipo nodo", nodo.TipoNodo, 100, errori);
            Richiesto("Nodi", nodo.RigaExcel, "Descrizione nodo", nodo.DescrizioneNodo, 200, errori);
            Lunghezza("Nodi", nodo.RigaExcel, "Chiave padre", nodo.ChiavePadre, 50, errori);
            Lunghezza("Nodi", nodo.RigaExcel, "Codice nodo", nodo.CodiceNodo, 50, errori);
            Lunghezza("Nodi", nodo.RigaExcel, "Note", nodo.Note, 500, errori);
            if (!string.IsNullOrWhiteSpace(nodo.ChiaveNodo) && !chiavi.TryAdd(nodo.ChiaveNodo, nodo))
                errori.Add(new("Nodi", nodo.RigaExcel, "Chiave nodo", "La chiave nodo è duplicata nel file."));
            if (!tipiAmmessi.Contains(nodo.TipoNodo))
                errori.Add(new("Nodi", nodo.RigaExcel, "Tipo nodo", "Il tipo nodo non esiste oppure non è attivo."));
            if (nodo.QuantitaBase <= 0)
                errori.Add(new("Nodi", nodo.RigaExcel, "Quantità base", "La quantità deve essere maggiore di zero."));
            if (nodo.OrdineVisualizzazione < 0)
                errori.Add(new("Nodi", nodo.RigaExcel, "Ordine", "L'ordine non può essere negativo."));
        }

        var radici = nodi.Where(x => string.IsNullOrWhiteSpace(x.ChiavePadre)).ToArray();
        if (nodi.Count == 0)
            errori.Add(new("Nodi", 0, "Foglio", "Inserire almeno un nodo."));
        if (radici.Length != 1)
            errori.Add(new("Nodi", 0, "Chiave padre", "Deve esistere un solo nodo radice con Chiave padre vuota."));
        else if (!radici[0].Attivo)
            errori.Add(new("Nodi", radici[0].RigaExcel, "Attivo", "Il nodo radice deve essere attivo."));

        foreach (var nodo in nodi.Where(x => !string.IsNullOrWhiteSpace(x.ChiavePadre)))
        {
            if (!chiavi.TryGetValue(nodo.ChiavePadre!, out var padre))
            {
                errori.Add(new("Nodi", nodo.RigaExcel, "Chiave padre", "La chiave padre non esiste nel foglio Nodi."));
                continue;
            }
            if (string.Equals(nodo.ChiaveNodo, nodo.ChiavePadre, StringComparison.OrdinalIgnoreCase))
                errori.Add(new("Nodi", nodo.RigaExcel, "Chiave padre", "Un nodo non può essere padre di se stesso."));
            if (nodo.Attivo && !padre.Attivo)
                errori.Add(new("Nodi", nodo.RigaExcel, "Attivo", "Un nodo attivo non può avere un padre non attivo."));
        }

        foreach (var nodo in nodi)
        {
            var visitati = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var corrente = nodo;
            while (!string.IsNullOrWhiteSpace(corrente.ChiavePadre) && chiavi.TryGetValue(corrente.ChiavePadre, out var padre))
            {
                if (!visitati.Add(corrente.ChiaveNodo))
                {
                    errori.Add(new("Nodi", nodo.RigaExcel, "Chiave padre", "La gerarchia contiene un ciclo."));
                    break;
                }
                corrente = padre;
            }
        }

        var codiciMateriale = materiali.Select(x => x.CodiceMateriale).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var duplicatiMateriale = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var materiale in materialiImportati)
        {
            Richiesto("Materiali", materiale.RigaExcel, "Chiave nodo", materiale.ChiaveNodo, 50, errori);
            Richiesto("Materiali", materiale.RigaExcel, "Codice materiale", materiale.CodiceMateriale, 50, errori);
            Lunghezza("Materiali", materiale.RigaExcel, "Note", materiale.Note, 500, errori);
            if (!chiavi.ContainsKey(materiale.ChiaveNodo))
                errori.Add(new("Materiali", materiale.RigaExcel, "Chiave nodo", "La chiave nodo non esiste nel foglio Nodi."));
            if (!codiciMateriale.Contains(materiale.CodiceMateriale))
                errori.Add(new("Materiali", materiale.RigaExcel, "Codice materiale", "Il materiale non esiste oppure non è attivo."));
            if (materiale.Quantita <= 0 || materiale.CoeffScartoPerc < 0 || materiale.CostoUnitario < 0)
                errori.Add(new("Materiali", materiale.RigaExcel, "Valori", "Quantità deve essere positiva; scarto e costo non possono essere negativi."));
            if (!duplicatiMateriale.Add($"{materiale.ChiaveNodo}\u001F{materiale.CodiceMateriale}"))
                errori.Add(new("Materiali", materiale.RigaExcel, "Codice materiale", "Il materiale è duplicato sullo stesso nodo."));
        }

        var codiciLavorazione = lavorazioni.Select(x => x.CodiceLavorazione).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var sequenze = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var lavorazione in lavorazioniImportate)
        {
            Richiesto("Lavorazioni", lavorazione.RigaExcel, "Chiave nodo", lavorazione.ChiaveNodo, 50, errori);
            Richiesto("Lavorazioni", lavorazione.RigaExcel, "Codice lavorazione", lavorazione.CodiceLavorazione, 50, errori);
            Lunghezza("Lavorazioni", lavorazione.RigaExcel, "Note", lavorazione.Note, 500, errori);
            if (!chiavi.ContainsKey(lavorazione.ChiaveNodo))
                errori.Add(new("Lavorazioni", lavorazione.RigaExcel, "Chiave nodo", "La chiave nodo non esiste nel foglio Nodi."));
            if (!codiciLavorazione.Contains(lavorazione.CodiceLavorazione))
                errori.Add(new("Lavorazioni", lavorazione.RigaExcel, "Codice lavorazione", "La lavorazione non esiste oppure non è attiva."));
            if (lavorazione.Sequenza <= 0 || lavorazione.TempoSetupMin < 0 || lavorazione.TempoPezzoMin < 0 || lavorazione.CostoOrario < 0 || lavorazione.CostoFisso < 0)
                errori.Add(new("Lavorazioni", lavorazione.RigaExcel, "Valori", "Sequenza deve essere positiva; tempi e costi non possono essere negativi."));
            if (!sequenze.Add($"{lavorazione.ChiaveNodo}\u001F{lavorazione.Sequenza}"))
                errori.Add(new("Lavorazioni", lavorazione.RigaExcel, "Sequenza", "La sequenza è duplicata sullo stesso nodo."));
        }
    }

    private static void Richiesto(string foglio, int riga, string campo, string? valore, int massimo, ICollection<DistintaImportazioneErrore> errori)
    {
        if (string.IsNullOrWhiteSpace(valore)) errori.Add(new(foglio, riga, campo, "Il valore è obbligatorio."));
        else if (valore.Length > massimo) errori.Add(new(foglio, riga, campo, $"Il valore supera {massimo} caratteri."));
    }

    private static void Lunghezza(string foglio, int riga, string campo, string? valore, int massimo, ICollection<DistintaImportazioneErrore> errori)
    {
        if (valore?.Length > massimo) errori.Add(new(foglio, riga, campo, $"Il valore supera {massimo} caratteri."));
    }

    private static decimal Decimale(IReadOnlyDictionary<string, string> riga, string campo, string foglio, int numero, ICollection<DistintaImportazioneErrore> errori)
    {
        var testo = Testo(riga, campo);
        var primaCultura = testo.Contains(',') ? CulturaItaliana : CulturaInvariante;
        var secondaCultura = testo.Contains(',') ? CulturaInvariante : CulturaItaliana;
        if (decimal.TryParse(testo, NumberStyles.Number, primaCultura, out var valore) ||
            decimal.TryParse(testo, NumberStyles.Number, secondaCultura, out valore)) return valore;
        errori.Add(new(foglio, numero, campo, "Inserire un numero valido."));
        return 0m;
    }

    private static int Intero(IReadOnlyDictionary<string, string> riga, string campo, string foglio, int numero, ICollection<DistintaImportazioneErrore> errori)
    {
        var testo = Testo(riga, campo);
        if (int.TryParse(testo, NumberStyles.Integer, CulturaItaliana, out var valore)) return valore;
        errori.Add(new(foglio, numero, campo, "Inserire un numero intero valido."));
        return 0;
    }

    private static bool Booleano(IReadOnlyDictionary<string, string> riga, string campo, string foglio, int numero, ICollection<DistintaImportazioneErrore> errori)
    {
        var testo = Testo(riga, campo);
        if (new[] { "sì", "si", "1", "true", "attivo" }.Contains(testo, StringComparer.OrdinalIgnoreCase)) return true;
        if (new[] { "no", "0", "false", "non attivo" }.Contains(testo, StringComparer.OrdinalIgnoreCase)) return false;
        errori.Add(new(foglio, numero, campo, "Usare Sì oppure No."));
        return false;
    }

    private static int Riga(IReadOnlyDictionary<string, string> riga) =>
        int.TryParse(Testo(riga, "__RigaExcel"), out var numero) ? numero : 0;
    private static string Testo(IReadOnlyDictionary<string, string> riga, string campo) =>
        riga.TryGetValue(campo, out var valore) ? valore.Trim() : string.Empty;
    private static string? TestoNull(IReadOnlyDictionary<string, string> riga, string campo) =>
        string.IsNullOrWhiteSpace(Testo(riga, campo)) ? null : Testo(riga, campo);

    private static XDocument CaricaXml(ZipArchive archivio, string percorso)
    {
        var entry = archivio.GetEntry(percorso.Replace('\\', '/'))
            ?? throw new InvalidDataException($"Parte Excel mancante: {percorso}");
        using var stream = entry.Open();
        return XDocument.Load(stream, LoadOptions.None);
    }

    private static IReadOnlyList<string> LeggiStringheCondivise(ZipArchive archivio)
    {
        var entry = archivio.GetEntry("xl/sharedStrings.xml");
        if (entry is null) return [];
        using var stream = entry.Open();
        return XDocument.Load(stream)
            .Descendants(Spreadsheet + "si")
            .Select(x => string.Concat(x.Descendants(Spreadsheet + "t").Select(t => t.Value)))
            .ToArray();
    }

    private static string ValoreCella(XElement cella, IReadOnlyList<string> condivise)
    {
        var tipo = (string?)cella.Attribute("t");
        if (tipo == "inlineStr") return string.Concat(cella.Descendants(Spreadsheet + "t").Select(x => x.Value));
        var valore = cella.Element(Spreadsheet + "v")?.Value ?? string.Empty;
        if (tipo == "s" && int.TryParse(valore, out var indice) && indice >= 0 && indice < condivise.Count) return condivise[indice];
        if (tipo == "b") return valore == "1" ? "Sì" : "No";
        return valore;
    }

    private static int IndiceColonna(string? riferimento)
    {
        if (string.IsNullOrWhiteSpace(riferimento)) return -1;
        var indice = 0;
        foreach (var carattere in riferimento.TakeWhile(char.IsLetter)) indice = (indice * 26) + (char.ToUpperInvariant(carattere) - 'A' + 1);
        return indice - 1;
    }

    private static string NormalizzaPercorsoFoglio(string target)
    {
        var valore = target.Replace('\\', '/').TrimStart('/');
        return valore.StartsWith("xl/", StringComparison.OrdinalIgnoreCase) ? valore : $"xl/{valore}";
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
            new XElement(Spreadsheet + "cellStyleXfs", new XAttribute("count", 1), new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 0), new XAttribute("fontId", 0), new XAttribute("fillId", 0), new XAttribute("borderId", 0))),
            new XElement(Spreadsheet + "cellXfs", new XAttribute("count", 2),
                new XElement(Spreadsheet + "xf", new XAttribute("numFmtId", 0), new XAttribute("fontId", 0), new XAttribute("fillId", 0), new XAttribute("borderId", 0), new XAttribute("xfId", 0)),
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
            new XElement(Spreadsheet + "cols", Enumerable.Range(1, Math.Max(1, righe.FirstOrDefault()?.Count ?? 1)).Select(i => new XElement(Spreadsheet + "col", new XAttribute("min", i), new XAttribute("max", i), new XAttribute("width", i == 1 ? 24 : 20), new XAttribute("customWidth", 1)))),
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

    private static string Numero(decimal valore) => valore.ToString("0.####", CulturaItaliana);
}

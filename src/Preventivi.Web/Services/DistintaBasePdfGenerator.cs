using System.Globalization;
using System.Text;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Services;

public sealed class DistintaBasePdfGenerator
{
    private const float PageWidth = 595.28f;
    private const float PageHeight = 841.89f;
    private const float Margin = 38f;
    private const float BottomLimit = 786f;
    private const float ContentWidth = PageWidth - (Margin * 2);

    private static readonly PdfColor Primary = new(0.12f, 0.35f, 0.57f);
    private static readonly PdfColor PrimaryLight = new(0.91f, 0.95f, 0.98f);
    private static readonly PdfColor SurfaceMuted = new(0.96f, 0.97f, 0.98f);
    private static readonly PdfColor Border = new(0.83f, 0.86f, 0.89f);
    private static readonly PdfColor Text = new(0.15f, 0.17f, 0.20f);
    private static readonly PdfColor Muted = new(0.43f, 0.48f, 0.54f);
    private static readonly PdfColor Success = new(0.18f, 0.55f, 0.34f);
    private static readonly PdfColor White = new(1f, 1f, 1f);

    public byte[] Genera(
        ArticoloDettaglio articolo,
        IReadOnlyList<DistintaBaseReportNodo> nodi,
        DateTimeOffset generatoIl)
    {
        ArgumentNullException.ThrowIfNull(articolo);
        ArgumentNullException.ThrowIfNull(nodi);

        var report = new ReportLayout(articolo, generatoIl);
        report.DisegnaTestataArticolo(nodi);

        if (nodi.Count == 0)
        {
            report.DisegnaMessaggioVuoto();
        }
        else
        {
            foreach (var nodo in nodi)
            {
                report.DisegnaNodo(nodo);
            }
        }

        return report.Completa();
    }

    private sealed class ReportLayout
    {
        private readonly ArticoloDettaglio _articolo;
        private readonly DateTimeOffset _generatoIl;
        private readonly List<PdfPageCanvas> _pagine = [];
        private PdfPageCanvas _pagina = null!;
        private float _y;

        public ReportLayout(
            ArticoloDettaglio articolo,
            DateTimeOffset generatoIl)
        {
            _articolo = articolo;
            _generatoIl = generatoIl;
            NuovaPagina();
        }

        public void DisegnaTestataArticolo(
            IReadOnlyList<DistintaBaseReportNodo> nodi)
        {
            _pagina.FillRect(Margin, _y, ContentWidth, 82f, SurfaceMuted);
            _pagina.FillRect(Margin, _y, 5f, 82f, Primary);
            _pagina.Text(Margin + 16f, _y + 12f, "ARTICOLO", 8f, true, Primary);
            _pagina.Text(
                Margin + 16f,
                _y + 27f,
                Abbrevia($"{_articolo.CodiceArticolo} - {_articolo.Descrizione}", 76),
                16f,
                true,
                Text);

            var versione = string.IsNullOrWhiteSpace(_articolo.Versione)
                ? "-"
                : _articolo.Versione;
            var cliente = string.IsNullOrWhiteSpace(_articolo.Cliente)
                ? "Nessun cliente associato"
                : _articolo.Cliente;
            _pagina.Text(
                Margin + 16f,
                _y + 53f,
                $"Versione: {versione}    Cliente: {Abbrevia(cliente, 42)}",
                9f,
                false,
                Muted);
            _pagina.TextRight(
                Margin + ContentWidth - 15f,
                _y + 53f,
                _articolo.Attivo ? "ARTICOLO ATTIVO" : "ARTICOLO NON ATTIVO",
                8f,
                true,
                _articolo.Attivo ? Success : Muted);
            _y += 96f;

            var materiali = nodi.Sum(x => x.Materiali.Count);
            var lavorazioni = nodi.Sum(x => x.Lavorazioni.Count);
            DisegnaIndicatore(Margin, "NODI", nodi.Count.ToString(CultureInfo.InvariantCulture));
            DisegnaIndicatore(Margin + 176f, "MATERIALI", materiali.ToString(CultureInfo.InvariantCulture));
            DisegnaIndicatore(Margin + 352f, "LAVORAZIONI", lavorazioni.ToString(CultureInfo.InvariantCulture));
            _y += 66f;

            _pagina.Text(Margin, _y, "ESPLOSIONE DELLA STRUTTURA", 10f, true, Primary);
            _pagina.Line(Margin, _y + 16f, Margin + ContentWidth, _y + 16f, Border, 0.8f);
            _y += 29f;
        }

        public void DisegnaMessaggioVuoto()
        {
            AssicuraSpazio(68f);
            _pagina.FillRect(Margin, _y, ContentWidth, 54f, SurfaceMuted);
            _pagina.Text(
                Margin + 16f,
                _y + 19f,
                "Nessun nodo presente nella distinta base.",
                11f,
                false,
                Muted);
            _y += 66f;
        }

        public void DisegnaNodo(DistintaBaseReportNodo contenuto)
        {
            var spazioMinimo = contenuto.Materiali.Count > 0 || contenuto.Lavorazioni.Count > 0
                ? 125f
                : 76f;
            AssicuraSpazio(spazioMinimo);
            var nodo = contenuto.Nodo;
            var indentazione = Math.Min(nodo.Livello * 13f, 78f);
            var sfondo = nodo.IdNodoPadre is null ? PrimaryLight : SurfaceMuted;

            _pagina.FillRect(Margin, _y, ContentWidth, 48f, sfondo);
            _pagina.FillRect(Margin, _y, 4f, 48f, nodo.Attivo ? Primary : Muted);
            if (nodo.Livello > 0)
            {
                var lineaX = Margin + 14f + indentazione - 8f;
                _pagina.Line(lineaX, _y, lineaX, _y + 23f, Border, 1f);
                _pagina.Line(lineaX, _y + 23f, lineaX + 9f, _y + 23f, Border, 1f);
            }

            var titolo = string.IsNullOrWhiteSpace(nodo.CodiceNodo)
                ? nodo.DescrizioneNodo
                : $"{nodo.CodiceNodo} - {nodo.DescrizioneNodo}";
            _pagina.Text(
                Margin + 14f + indentazione,
                _y + 8f,
                $"L{nodo.Livello}  {Abbrevia(titolo, Math.Max(34, 75 - (nodo.Livello * 3)))}",
                11f,
                true,
                Text);
            _pagina.Text(
                Margin + 14f + indentazione,
                _y + 28f,
                $"{nodo.TipoNodo}  |  Quantita base {Numero(nodo.QuantitaBase, 4)}  |  Ordine {nodo.OrdineVisualizzazione}",
                8f,
                false,
                Muted);
            _pagina.TextRight(
                Margin + ContentWidth - 12f,
                _y + 18f,
                nodo.Attivo ? "ATTIVO" : "NON ATTIVO",
                8f,
                true,
                nodo.Attivo ? Success : Muted);
            _y += 58f;

            if (contenuto.Materiali.Count > 0)
            {
                DisegnaMateriali(contenuto.Materiali);
            }

            if (contenuto.Lavorazioni.Count > 0)
            {
                DisegnaLavorazioni(contenuto.Lavorazioni);
            }

            if (contenuto.Materiali.Count == 0 && contenuto.Lavorazioni.Count == 0)
            {
                AssicuraSpazio(23f);
                _pagina.Text(
                    Margin + 15f,
                    _y + 2f,
                    "Nessun materiale o lavorazione associato al nodo.",
                    8f,
                    false,
                    Muted);
                _y += 23f;
            }

            _y += 10f;
        }

        public byte[] Completa()
        {
            for (var indice = 0; indice < _pagine.Count; indice++)
            {
                var pagina = _pagine[indice];
                pagina.Line(Margin, 808f, Margin + ContentWidth, 808f, Border, 0.7f);
                pagina.Text(
                    Margin,
                    817f,
                    $"Distinta base {_articolo.CodiceArticolo}",
                    7f,
                    false,
                    Muted);
                pagina.TextRight(
                    Margin + ContentWidth,
                    817f,
                    $"Pagina {indice + 1} di {_pagine.Count}",
                    7f,
                    false,
                    Muted);
            }

            return PdfWriter.Build(_pagine);
        }

        private void NuovaPagina()
        {
            _pagina = new PdfPageCanvas(PageHeight);
            _pagine.Add(_pagina);
            _pagina.FillRect(0f, 0f, PageWidth, 66f, Primary);
            _pagina.FillRect(Margin, 17f, 31f, 31f, White);
            _pagina.Text(Margin + 10f, 23f, "P", 15f, true, Primary);
            _pagina.Text(Margin + 44f, 17f, "PREVENTIVI WEB", 8f, true, White);
            _pagina.Text(Margin + 44f, 31f, "Esplosione distinta base", 16f, true, White);
            _pagina.TextRight(
                Margin + ContentWidth,
                25f,
                $"Generato il {_generatoIl:dd/MM/yyyy HH:mm}",
                8f,
                false,
                White);
            _y = 84f;
        }

        private void AssicuraSpazio(float altezza)
        {
            if (_y + altezza <= BottomLimit)
            {
                return;
            }

            NuovaPagina();
        }

        private void DisegnaIndicatore(float x, string etichetta, string valore)
        {
            _pagina.FillRect(x, _y, 167f, 51f, PrimaryLight);
            _pagina.Text(x + 12f, _y + 10f, etichetta, 7f, true, Muted);
            _pagina.Text(x + 12f, _y + 24f, valore, 16f, true, Primary);
        }

        private void DisegnaMateriali(
            IReadOnlyList<DistintaMaterialeDettaglio> materiali)
        {
            AssicuraSpazio(47f);
            _pagina.Text(Margin + 10f, _y, "MATERIALI", 8f, true, Primary);
            _y += 15f;
            DisegnaIntestazioneMateriali();

            for (var indice = 0; indice < materiali.Count; indice++)
            {
                var materiale = materiali[indice];
                if (_y + 20f > BottomLimit)
                {
                    NuovaPagina();
                    _pagina.Text(Margin, _y, "MATERIALI - segue", 8f, true, Primary);
                    _y += 15f;
                    DisegnaIntestazioneMateriali();
                }

                if (indice % 2 == 1)
                {
                    _pagina.FillRect(Margin, _y, ContentWidth, 19f, SurfaceMuted);
                }

                _pagina.Text(Margin + 6f, _y + 5f, Abbrevia(materiale.CodiceMateriale, 12), 7f, true, Text);
                _pagina.Text(Margin + 81f, _y + 5f, Abbrevia(materiale.DescrizioneMateriale, 38), 7f, false, Text);
                _pagina.Text(Margin + 306f, _y + 5f, Abbrevia(materiale.CodiceUM, 5), 7f, false, Text);
                _pagina.TextRight(Margin + 399f, _y + 5f, Numero(materiale.Quantita, 4), 7f, false, Text);
                _pagina.TextRight(Margin + 452f, _y + 5f, Numero(materiale.CoeffScartoPerc, 2), 7f, false, Text);
                _pagina.TextRight(Margin + ContentWidth - 6f, _y + 5f, $"{Numero(materiale.CostoUnitario, 4)} EUR", 7f, false, Text);
                _y += 19f;
            }

            _y += 8f;
        }

        private void DisegnaIntestazioneMateriali()
        {
            _pagina.FillRect(Margin, _y, ContentWidth, 20f, Primary);
            _pagina.Text(Margin + 6f, _y + 6f, "CODICE", 6.5f, true, White);
            _pagina.Text(Margin + 81f, _y + 6f, "DESCRIZIONE", 6.5f, true, White);
            _pagina.Text(Margin + 306f, _y + 6f, "UM", 6.5f, true, White);
            _pagina.TextRight(Margin + 399f, _y + 6f, "QUANTITA", 6.5f, true, White);
            _pagina.TextRight(Margin + 452f, _y + 6f, "SCARTO %", 6.5f, true, White);
            _pagina.TextRight(Margin + ContentWidth - 6f, _y + 6f, "COSTO UNIT.", 6.5f, true, White);
            _y += 20f;
        }

        private void DisegnaLavorazioni(
            IReadOnlyList<DistintaLavorazioneDettaglio> lavorazioni)
        {
            AssicuraSpazio(47f);
            _pagina.Text(Margin + 10f, _y, "LAVORAZIONI", 8f, true, Primary);
            _y += 15f;
            DisegnaIntestazioneLavorazioni();

            for (var indice = 0; indice < lavorazioni.Count; indice++)
            {
                var lavorazione = lavorazioni[indice];
                if (_y + 20f > BottomLimit)
                {
                    NuovaPagina();
                    _pagina.Text(Margin, _y, "LAVORAZIONI - segue", 8f, true, Primary);
                    _y += 15f;
                    DisegnaIntestazioneLavorazioni();
                }

                if (indice % 2 == 1)
                {
                    _pagina.FillRect(Margin, _y, ContentWidth, 19f, SurfaceMuted);
                }

                _pagina.Text(Margin + 6f, _y + 5f, lavorazione.Sequenza.ToString(CultureInfo.InvariantCulture), 7f, true, Text);
                _pagina.Text(Margin + 42f, _y + 5f, Abbrevia(lavorazione.CodiceLavorazione, 11), 7f, true, Text);
                _pagina.Text(Margin + 111f, _y + 5f, Abbrevia(lavorazione.DescrizioneLavorazione, 29), 7f, false, Text);
                _pagina.TextRight(Margin + 336f, _y + 5f, Numero(lavorazione.TempoSetupMin, 2), 7f, false, Text);
                _pagina.TextRight(Margin + 394f, _y + 5f, Numero(lavorazione.TempoPezzoMin, 4), 7f, false, Text);
                _pagina.TextRight(Margin + 452f, _y + 5f, $"{Numero(lavorazione.CostoOrario, 2)} EUR", 7f, false, Text);
                _pagina.TextRight(Margin + ContentWidth - 6f, _y + 5f, $"{Numero(lavorazione.CostoFisso, 2)} EUR", 7f, false, Text);
                _y += 19f;
            }

            _y += 8f;
        }

        private void DisegnaIntestazioneLavorazioni()
        {
            _pagina.FillRect(Margin, _y, ContentWidth, 20f, Primary);
            _pagina.Text(Margin + 6f, _y + 6f, "SEQ.", 6.5f, true, White);
            _pagina.Text(Margin + 42f, _y + 6f, "CODICE", 6.5f, true, White);
            _pagina.Text(Margin + 111f, _y + 6f, "DESCRIZIONE", 6.5f, true, White);
            _pagina.TextRight(Margin + 336f, _y + 6f, "SETUP", 6.5f, true, White);
            _pagina.TextRight(Margin + 394f, _y + 6f, "TEMPO PZ", 6.5f, true, White);
            _pagina.TextRight(Margin + 452f, _y + 6f, "COSTO/H", 6.5f, true, White);
            _pagina.TextRight(Margin + ContentWidth - 6f, _y + 6f, "COSTO FISSO", 6.5f, true, White);
            _y += 20f;
        }
    }

    private sealed class PdfPageCanvas(float pageHeight)
    {
        private readonly StringBuilder _commands = new();

        public byte[] GetContent() => Encoding.Latin1.GetBytes(_commands.ToString());

        public void FillRect(float x, float top, float width, float height, PdfColor color)
        {
            var y = pageHeight - top - height;
            _commands.AppendFormat(
                CultureInfo.InvariantCulture,
                "{0} {1} {2} rg {3} {4} {5} {6} re f\n",
                color.R,
                color.G,
                color.B,
                x,
                y,
                width,
                height);
        }

        public void Line(float x1, float top1, float x2, float top2, PdfColor color, float width)
        {
            _commands.AppendFormat(
                CultureInfo.InvariantCulture,
                "{0} {1} {2} RG {3} w {4} {5} m {6} {7} l S\n",
                color.R,
                color.G,
                color.B,
                width,
                x1,
                pageHeight - top1,
                x2,
                pageHeight - top2);
        }

        public void Text(float x, float top, string value, float size, bool bold, PdfColor color)
        {
            var y = pageHeight - top - size;
            _commands.AppendFormat(
                CultureInfo.InvariantCulture,
                "BT /{0} {1} Tf {2} {3} {4} rg {5} {6} Td ({7}) Tj ET\n",
                bold ? "F2" : "F1",
                size,
                color.R,
                color.G,
                color.B,
                x,
                y,
                Escape(value));
        }

        public void TextRight(float right, float top, string value, float size, bool bold, PdfColor color)
        {
            var estimatedWidth = value.Length * size * (bold ? 0.56f : 0.51f);
            Text(Math.Max(Margin, right - estimatedWidth), top, value, size, bold, color);
        }

        private static string Escape(string value) =>
            Normalizza(value)
                .Replace("\\", "\\\\", StringComparison.Ordinal)
                .Replace("(", "\\(", StringComparison.Ordinal)
                .Replace(")", "\\)", StringComparison.Ordinal);
    }

    private static class PdfWriter
    {
        public static byte[] Build(IReadOnlyList<PdfPageCanvas> pages)
        {
            var objects = new List<byte[]>();
            var pageObjectNumbers = Enumerable
                .Range(0, pages.Count)
                .Select(index => 5 + (index * 2))
                .ToArray();

            objects.Add(Ascii("<< /Type /Catalog /Pages 2 0 R >>"));
            objects.Add(Ascii($"<< /Type /Pages /Count {pages.Count} /Kids [{string.Join(' ', pageObjectNumbers.Select(x => $"{x} 0 R"))}] >>"));
            objects.Add(Ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"));
            objects.Add(Ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"));

            for (var index = 0; index < pages.Count; index++)
            {
                var contentObject = 6 + (index * 2);
                var content = pages[index].GetContent();
                objects.Add(Ascii($"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {PageWidth.ToString(CultureInfo.InvariantCulture)} {PageHeight.ToString(CultureInfo.InvariantCulture)}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {contentObject} 0 R >>"));
                objects.Add(StreamObject(content));
            }

            using var output = new MemoryStream();
            Write(output, Encoding.Latin1.GetBytes("%PDF-1.4\n%\u00E2\u00E3\u00CF\u00D3\n"));
            var offsets = new List<long> { 0 };

            for (var index = 0; index < objects.Count; index++)
            {
                offsets.Add(output.Position);
                Write(output, Ascii($"{index + 1} 0 obj\n"));
                Write(output, objects[index]);
                Write(output, Ascii("\nendobj\n"));
            }

            var xref = output.Position;
            Write(output, Ascii($"xref\n0 {objects.Count + 1}\n"));
            Write(output, Ascii("0000000000 65535 f \n"));
            foreach (var offset in offsets.Skip(1))
            {
                Write(output, Ascii($"{offset:0000000000} 00000 n \n"));
            }

            Write(output, Ascii($"trailer\n<< /Size {objects.Count + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF"));
            return output.ToArray();
        }

        private static byte[] StreamObject(byte[] content)
        {
            using var stream = new MemoryStream();
            Write(stream, Ascii($"<< /Length {content.Length} >>\nstream\n"));
            Write(stream, content);
            Write(stream, Ascii("\nendstream"));
            return stream.ToArray();
        }

        private static byte[] Ascii(string value) => Encoding.ASCII.GetBytes(value);

        private static void Write(Stream stream, byte[] bytes) =>
            stream.Write(bytes, 0, bytes.Length);
    }

    private static string Numero(decimal value, int decimals) =>
        value.ToString($"N{decimals}", CultureInfo.GetCultureInfo("it-IT"));

    private static string Abbrevia(string? value, int maximum)
    {
        var normalized = Normalizza(value ?? string.Empty).Trim();
        return normalized.Length <= maximum
            ? normalized
            : $"{normalized[..Math.Max(1, maximum - 3)]}...";
    }

    private static string Normalizza(string value) =>
        value
            .Replace('\u2013', '-')
            .Replace('\u2014', '-')
            .Replace('\u2019', '\'')
            .Replace('\u00A0', ' ');

    private readonly record struct PdfColor(float R, float G, float B);
}

using System.Text;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Services;
using Xunit;

namespace Preventivi.Web.Tests.Services;

public sealed class DistintaBasePdfGeneratorTests
{
    [Fact]
    public void Genera_ConGerarchiaMaterialiELavorazioni_ProducePdfValido()
    {
        var generatore = new DistintaBasePdfGenerator();
        var articolo = new ArticoloDettaglio
        {
            IdArticolo = 2,
            CodiceArticolo = "GAB.01.002",
            Descrizione = "Espositore promozionale",
            Versione = "A",
            Cliente = "TEST - Cliente prova",
            Attivo = true
        };
        var nodi = new[]
        {
            new DistintaBaseReportNodo(
                new DistintaNodoItem
                {
                    IdNodoDistinta = 10,
                    IdArticolo = 2,
                    IdTipoNodo = 1,
                    TipoNodo = "Prodotto finito",
                    CodiceNodo = "ESP_COMPLETO",
                    DescrizioneNodo = "Espositore completo",
                    QuantitaBase = 1m,
                    Livello = 0,
                    OrdineVisualizzazione = 10,
                    Attivo = true
                },
                [
                    new DistintaMaterialeDettaglio
                    {
                        CodiceMateriale = "CARTA-01",
                        DescrizioneMateriale = "Cartone microonda bianco",
                        CodiceUM = "MQ",
                        Quantita = 2.5m,
                        CoeffScartoPerc = 3m,
                        CostoUnitario = 1.25m
                    }
                ],
                [
                    new DistintaLavorazioneDettaglio
                    {
                        Sequenza = 10,
                        CodiceLavorazione = "STAMPA",
                        DescrizioneLavorazione = "Stampa digitale",
                        TempoSetupMin = 15m,
                        TempoPezzoMin = 0.8m,
                        CostoOrario = 45m,
                        CostoFisso = 10m
                    }
                ])
        };

        var pdf = generatore.Genera(
            articolo,
            nodi,
            new DateTimeOffset(2026, 11, 6, 12, 0, 0, TimeSpan.FromHours(1)));

        Assert.True(pdf.Length > 2_000);
        Assert.Equal("%PDF-1.4", Encoding.Latin1.GetString(pdf, 0, 8));
        var contenuto = Encoding.Latin1.GetString(pdf);
        Assert.Contains("Esplosione distinta base", contenuto);
        Assert.Contains("ESP_COMPLETO", contenuto);
        Assert.Contains("CARTA-01", contenuto);
        Assert.Contains("STAMPA", contenuto);
        Assert.Contains("%%EOF", contenuto);
    }
}

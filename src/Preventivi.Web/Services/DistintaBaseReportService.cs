using System.Text.RegularExpressions;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Services;

public sealed class DistintaBaseReportService : IDistintaBaseReportService
{
    private readonly IArticoloRepository _articoli;
    private readonly IDistintaBaseRepository _distinte;
    private readonly DistintaBasePdfGenerator _generatore;

    public DistintaBaseReportService(
        IArticoloRepository articoli,
        IDistintaBaseRepository distinte,
        DistintaBasePdfGenerator generatore)
    {
        _articoli = articoli;
        _distinte = distinte;
        _generatore = generatore;
    }

    public async Task<DistintaBasePdfResult?> GeneraPdfAsync(
        int idArticolo,
        CancellationToken cancellationToken = default)
    {
        if (idArticolo <= 0)
        {
            return null;
        }

        var articolo = await _articoli.GetDettaglioAsync(
            idArticolo,
            cancellationToken);
        if (articolo is null)
        {
            return null;
        }

        var nodi = await _distinte.GetNodiAsync(
            idArticolo,
            cancellationToken);
        var contenuti = new List<DistintaBaseReportNodo>(nodi.Count);

        foreach (var nodo in nodi)
        {
            cancellationToken.ThrowIfCancellationRequested();
            contenuti.Add(new DistintaBaseReportNodo(
                nodo,
                await _distinte.GetMaterialiAsync(
                    nodo.IdNodoDistinta,
                    cancellationToken),
                await _distinte.GetLavorazioniAsync(
                    nodo.IdNodoDistinta,
                    cancellationToken)));
        }

        var nomeSicuro = Regex.Replace(
            articolo.CodiceArticolo,
            "[^A-Za-z0-9._-]+",
            "-").Trim('-');
        if (string.IsNullOrWhiteSpace(nomeSicuro))
        {
            nomeSicuro = articolo.IdArticolo.ToString();
        }

        return new DistintaBasePdfResult(
            $"DistintaBase_{nomeSicuro}.pdf",
            _generatore.Genera(
                articolo,
                contenuti,
                DateTimeOffset.Now));
    }
}

public sealed record DistintaBaseReportNodo(
    DistintaNodoItem Nodo,
    IReadOnlyList<DistintaMaterialeDettaglio> Materiali,
    IReadOnlyList<DistintaLavorazioneDettaglio> Lavorazioni);

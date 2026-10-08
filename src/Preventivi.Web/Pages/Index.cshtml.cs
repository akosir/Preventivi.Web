using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages;

public class IndexModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public IReadOnlyList<DashboardKpiItem> Indicatori { get; private set; }
        = Array.Empty<DashboardKpiItem>();

    public IReadOnlyList<PreventivoListItem> UltimiPreventivi { get; private set; }
        = Array.Empty<PreventivoListItem>();

    public IReadOnlyList<DashboardAlertItem> AlertOperativi { get; private set; }
        = Array.Empty<DashboardAlertItem>();

    public IReadOnlyList<DashboardChartItem> AndamentoPreventivi { get; private set; }
        = Array.Empty<DashboardChartItem>();

    public int AlertCount => AlertOperativi.Count;

    public IndexModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        var preventivi =
            await _preventivoRepository.GetElencoAsync(cancellationToken);

        var preventiviDaInviare =
            preventivi.Count(IsDaInviare);

        Indicatori =
        [
            new DashboardKpiItem(
                "Richieste aperte",
                "-",
                "Modulo richieste non collegato",
                "R"),
            new DashboardKpiItem(
                "Preventivi",
                preventivi.Count.ToString(),
                $"{preventiviDaInviare} da inviare",
                "P"),
            new DashboardKpiItem(
                "Campionature",
                "-",
                "Modulo campionature non collegato",
                "C"),
            new DashboardKpiItem(
                "Ordini fornitori",
                "-",
                "Modulo ordini non collegato",
                "O")
        ];

        UltimiPreventivi =
            preventivi
                .OrderByDescending(p => p.DataPreventivo)
                .ThenByDescending(p => p.NumeroPreventivo)
                .Take(4)
                .ToArray();

        AlertOperativi =
            CreaAlertOperativi(preventivi);

        AndamentoPreventivi =
            CreaAndamentoPreventivi(preventivi);
    }

    private static IReadOnlyList<DashboardAlertItem> CreaAlertOperativi(
        IReadOnlyList<PreventivoListItem> preventivi)
    {
        var alert = new List<DashboardAlertItem>();

        foreach (var preventivo in preventivi.Where(IsDaInviare).Take(3))
        {
            alert.Add(
                new DashboardAlertItem(
                    "warning",
                    "Preventivo da inviare",
                    $"{preventivo.NumeroCompleto} - {preventivo.Cliente}"));
        }

        foreach (var preventivo in preventivi.Where(IsDaVerificare).Take(3))
        {
            alert.Add(
                new DashboardAlertItem(
                    "danger",
                    "Preventivo da verificare",
                    $"{preventivo.NumeroCompleto} - {preventivo.Cliente}"));
        }

        foreach (var preventivo in preventivi.Where(IsBozza).Take(3))
        {
            alert.Add(
                new DashboardAlertItem(
                    "primary",
                    "Preventivo in bozza",
                    $"{preventivo.NumeroCompleto} - {preventivo.Cliente}"));
        }

        return alert
            .Take(6)
            .ToArray();
    }

    private static IReadOnlyList<DashboardChartItem> CreaAndamentoPreventivi(
        IReadOnlyList<PreventivoListItem> preventivi)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var firstMonth = new DateOnly(today.Year, today.Month, 1).AddMonths(-5);

        var mesi =
            Enumerable.Range(0, 6)
                .Select(offset => firstMonth.AddMonths(offset))
                .ToArray();

        var counts =
            mesi
                .Select(mese =>
                    preventivi.Count(p =>
                        p.DataPreventivo.Year == mese.Year &&
                        p.DataPreventivo.Month == mese.Month))
                .ToArray();

        var max = Math.Max(1, counts.Max());

        return mesi
            .Select((mese, index) =>
                new DashboardChartItem(
                    mese.ToString("MMM"),
                    counts[index],
                    Math.Max(10, (int)Math.Round((decimal)counts[index] / max * 100))))
            .ToArray();
    }

    public static string GetStatoBadge(string stato)
    {
        return stato switch
        {
            "Accettato" => "pfw-badge-success",
            "Pronto da Inviare"
                or "Da Verificare" => "pfw-badge-warning",
            "Respinto"
                or "Annullato" => "pfw-badge-danger",
            "Inviato"
                or "In Produzione" => "pfw-badge-primary",
            _ => "pfw-badge-secondary"
        };
    }

    private static bool IsDaInviare(PreventivoListItem preventivo) =>
        string.Equals(preventivo.Stato, "Pronto da Inviare", StringComparison.OrdinalIgnoreCase) ||
        string.Equals(preventivo.Stato, "Da inviare", StringComparison.OrdinalIgnoreCase);

    private static bool IsDaVerificare(PreventivoListItem preventivo) =>
        string.Equals(preventivo.Stato, "Da Verificare", StringComparison.OrdinalIgnoreCase);

    private static bool IsBozza(PreventivoListItem preventivo) =>
        string.Equals(preventivo.Stato, "Bozza", StringComparison.OrdinalIgnoreCase);
}

public sealed record DashboardKpiItem(
    string Titolo,
    string Valore,
    string Nota,
    string Sigla);

public sealed record DashboardAlertItem(
    string Livello,
    string Titolo,
    string Testo);

public sealed record DashboardChartItem(
    string Mese,
    int Conteggio,
    int AltezzaPercentuale);

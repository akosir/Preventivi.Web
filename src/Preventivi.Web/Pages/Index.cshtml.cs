using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Campionature;
using Preventivi.Core.Preventivi;
using Preventivi.Core.RichiesteClienti;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages;

public class IndexModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IRichiestaClienteRepository _richiestaClienteRepository;
    private readonly ICampionaturaRepository _campionaturaRepository;

    public IReadOnlyList<DashboardKpiItem> Indicatori { get; private set; }
        = Array.Empty<DashboardKpiItem>();

    public IReadOnlyList<PreventivoListItem> UltimiPreventivi { get; private set; }
        = Array.Empty<PreventivoListItem>();

    public IReadOnlyList<DashboardAlertItem> AlertOperativi { get; private set; }
        = Array.Empty<DashboardAlertItem>();

    public IReadOnlyList<DashboardChartItem> AndamentoPreventivi { get; private set; }
        = Array.Empty<DashboardChartItem>();

    public int AlertCount => AlertOperativi.Count;

    public bool PuoVisualizzarePreventivi { get; private set; }
    public bool PuoVisualizzareRichiesteClienti { get; private set; }
    public bool PuoVisualizzareCampionature { get; private set; }

    public IndexModel(
        IPreventivoRepository preventivoRepository,
        IRichiestaClienteRepository richiestaClienteRepository,
        ICampionaturaRepository campionaturaRepository)
    {
        _preventivoRepository = preventivoRepository;
        _richiestaClienteRepository = richiestaClienteRepository;
        _campionaturaRepository = campionaturaRepository;
    }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        PuoVisualizzarePreventivi =
            AutorizzazioneApplicazione.PuoAccedereAlPermesso(
                User,
                PermessiApplicazione.Preventivi);

        PuoVisualizzareRichiesteClienti =
            AutorizzazioneApplicazione.PuoAccedereAlPermesso(
                User,
                PermessiApplicazione.RichiesteClienti);

        PuoVisualizzareCampionature =
            AutorizzazioneApplicazione.PuoAccedereAlPermesso(
                User,
                PermessiApplicazione.Campionature);

        var preventivi = PuoVisualizzarePreventivi
            ? await _preventivoRepository.GetElencoAsync(cancellationToken)
            : Array.Empty<PreventivoListItem>();

        var richieste = PuoVisualizzareRichiesteClienti
            ? await _richiestaClienteRepository.GetElencoAsync(
                new RichiestaClienteFiltro(),
                cancellationToken)
            : Array.Empty<RichiestaClienteListItem>();

        var campionature = PuoVisualizzareCampionature
            ? await _campionaturaRepository.GetElencoAsync(
                new CampionaturaFiltro(),
                cancellationToken)
            : Array.Empty<CampionaturaListItem>();

        var preventiviDaInviare =
            preventivi.Count(IsDaInviare);

        var richiesteAperte = richieste.Count(richiesta =>
            !RichiestaClienteValori.StatoFinale(richiesta.Stato));

        var campionatureAperte = campionature.Count(campionatura =>
            !CampionaturaValori.StatoFinale(campionatura.Stato));

        Indicatori =
        [
            new DashboardKpiItem(
                "Richieste aperte",
                PuoVisualizzareRichiesteClienti ? richiesteAperte.ToString() : "-",
                PuoVisualizzareRichiesteClienti
                    ? "Dati aggiornati"
                    : "Accesso non autorizzato",
                "R"),
            new DashboardKpiItem(
                "Preventivi",
                PuoVisualizzarePreventivi ? preventivi.Count.ToString() : "-",
                PuoVisualizzarePreventivi
                    ? $"{preventiviDaInviare} da inviare"
                    : "Accesso non autorizzato",
                "P"),
            new DashboardKpiItem(
                "Campionature",
                PuoVisualizzareCampionature ? campionatureAperte.ToString() : "-",
                PuoVisualizzareCampionature
                    ? "Aperte"
                    : "Accesso non autorizzato",
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
            CreaAlertOperativi(preventivi, richieste, campionature);

        AndamentoPreventivi =
            CreaAndamentoPreventivi(preventivi);
    }

    private static IReadOnlyList<DashboardAlertItem> CreaAlertOperativi(
        IReadOnlyList<PreventivoListItem> preventivi,
        IReadOnlyList<RichiestaClienteListItem> richieste,
        IReadOnlyList<CampionaturaListItem> campionature)
    {
        var alert = new List<DashboardAlertItem>();
        var oggi = DateOnly.FromDateTime(DateTime.Today);
        var limiteScadenza = oggi.AddDays(7);

        foreach (var richiesta in richieste
                     .Where(elemento => !RichiestaClienteValori.StatoFinale(elemento.Stato))
                     .Where(elemento =>
                         elemento.Priorita == "Urgente" ||
                         elemento.DataScadenza <= limiteScadenza)
                     .OrderBy(elemento => elemento.DataScadenza ?? DateOnly.MaxValue)
                     .ThenByDescending(elemento => elemento.Priorita == "Urgente")
                     .Take(4))
        {
            var scaduta = richiesta.DataScadenza < oggi;
            var urgente = richiesta.Priorita == "Urgente";
            alert.Add(new DashboardAlertItem(
                scaduta ? "danger" : urgente ? "warning" : "primary",
                scaduta
                    ? "Richiesta cliente scaduta"
                    : urgente
                        ? "Richiesta cliente urgente"
                        : "Richiesta cliente in scadenza",
                $"{richiesta.NumeroCompleto} - {richiesta.Cliente} - {richiesta.Oggetto}"));
        }

        foreach (var preventivo in preventivi.Where(IsDaInviare).Take(3))
        {
            alert.Add(
                new DashboardAlertItem(
                    "warning",
                    "Preventivo da inviare",
                    $"{preventivo.NumeroCompleto} - {preventivo.Cliente}"));
        }

        foreach (var campionatura in campionature
                     .Where(elemento => !CampionaturaValori.StatoFinale(elemento.Stato))
                     .Where(elemento =>
                         elemento.Priorita == "Urgente" ||
                         elemento.DataPrevistaConsegna <= limiteScadenza)
                     .OrderBy(elemento => elemento.DataPrevistaConsegna ?? DateOnly.MaxValue)
                     .ThenByDescending(elemento => elemento.Priorita == "Urgente")
                     .Take(3))
        {
            var scaduta = campionatura.DataPrevistaConsegna < oggi;
            alert.Add(new DashboardAlertItem(
                scaduta ? "danger" : "warning",
                scaduta ? "Campionatura in ritardo" : "Campionatura da seguire",
                $"{campionatura.NumeroCompleto} - {campionatura.Cliente} - {campionatura.Oggetto}"));
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
            .Take(8)
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

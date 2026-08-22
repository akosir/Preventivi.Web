namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardDeadlinesModel
{
    public string Titolo { get; init; } = "Scadenze";

    public string? Sottotitolo { get; init; }

    public IReadOnlyList<DashboardDeadlineItemModel> Elementi { get; init; }
        = [];
}

public sealed class DashboardDeadlineItemModel
{
    public string Titolo { get; init; } = "";

    public string? Dettaglio { get; init; }

    public string Scadenza { get; init; } = "";

    public string Variante { get; init; } = "neutro";
}

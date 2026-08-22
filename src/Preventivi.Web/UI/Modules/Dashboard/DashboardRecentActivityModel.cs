namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardRecentActivityModel
{
    public string Titolo { get; init; } = "Attività recenti";

    public string? Sottotitolo { get; init; }

    public IReadOnlyList<DashboardRecentActivityItemModel> Elementi { get; init; }
        = [];
}

public sealed class DashboardRecentActivityItemModel
{
    public string Titolo { get; init; } = "";

    public string? Dettaglio { get; init; }

    public string DataOra { get; init; } = "";

    public string Variante { get; init; } = "neutro";
}

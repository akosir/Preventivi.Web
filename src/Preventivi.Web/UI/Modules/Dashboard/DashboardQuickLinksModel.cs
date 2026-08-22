namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardQuickLinksModel
{
    public string Titolo { get; init; } = "Collegamenti rapidi";

    public string? Sottotitolo { get; init; }

    public IReadOnlyList<DashboardQuickLinkItemModel> Elementi { get; init; }
        = [];
}

public sealed class DashboardQuickLinkItemModel
{
    public string Titolo { get; init; } = "";

    public string? Icona { get; init; }

    public string Url { get; init; } = "#";

    public bool Abilitato { get; init; } = true;
}

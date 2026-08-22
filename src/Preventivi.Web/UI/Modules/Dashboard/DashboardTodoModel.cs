namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardTodoModel
{
    public string Titolo { get; init; } = "Da fare";

    public string? Sottotitolo { get; init; }

    public IReadOnlyList<DashboardTodoItemModel> Elementi { get; init; }
        = [];
}

public sealed class DashboardTodoItemModel
{
    public string Titolo { get; init; } = "";

    public string Descrizione { get; init; } = "";

    public int Quantita { get; init; }

    public string Url { get; init; } = "#";

    public string VarianteBadge { get; init; } = "primary";
}
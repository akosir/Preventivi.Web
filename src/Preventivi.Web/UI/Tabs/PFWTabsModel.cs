namespace Preventivi.Web.UI.Tabs;

public sealed class PFWTabsModel
{
    public IReadOnlyList<PFWTabModel> Schede { get; init; } = [];
}

public sealed class PFWTabModel
{
    public string Id { get; init; } = "";

    public string Titolo { get; init; } = "";

    public string? Url { get; init; }

    public bool Attiva { get; init; }

    public bool Disabilitata { get; init; }

    public bool Visibile { get; init; } = true;
}
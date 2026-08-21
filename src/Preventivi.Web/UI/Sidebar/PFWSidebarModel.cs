namespace Preventivi.Web.UI.Sidebar;

public sealed class PFWSidebarModel
{
    public string Titolo { get; init; } = "";

    public string? Sottotitolo { get; init; }

    public string? Logo { get; init; }

    public string? Footer { get; init; }

    public IReadOnlyList<PFWSidebarGroupModel> Gruppi { get; init; } = [];
}

public sealed class PFWSidebarGroupModel
{
    public string Titolo { get; init; } = "";

    public string? Icona { get; init; }

    public bool Espanso { get; init; } = true;

    public IReadOnlyList<PFWSidebarItemModel> Voci { get; init; } = [];
}

public sealed class PFWSidebarItemModel
{
    public string Testo { get; init; } = "";

    public string? Icona { get; init; }

    public string? Url { get; init; }

    public bool Attiva { get; init; }

    public bool Disabilitata { get; init; }

    public bool Visibile { get; init; } = true;
}
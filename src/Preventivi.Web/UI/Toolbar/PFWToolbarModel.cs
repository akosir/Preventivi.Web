namespace Preventivi.Web.UI.Toolbar;

public sealed class PFWToolbarModel
{
    public string Titolo { get; init; } = "";

    public string? Sottotitolo { get; init; }

    public IReadOnlyList<PFWToolbarButton> Pulsanti { get; init; }
        = [];
}

public sealed class PFWToolbarButton
{
    public string Testo { get; init; } = "";

    public string? Icona { get; init; }

    public string? Url { get; init; }

    public string? OnClick { get; init; }

    public string CssClass { get; init; } = "pfw-btn-primary";

    public bool Abilitato { get; init; } = true;

    public bool Visibile { get; init; } = true;
}
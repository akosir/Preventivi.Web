namespace Preventivi.Web.UI.Button;

public sealed class PFWButtonModel
{
    public string Testo { get; init; } = "";

    public string? Icona { get; init; }

    public string? Url { get; init; }

    public string? OnClick { get; init; }

    public string Variante { get; init; } = "primary";

    public bool Abilitato { get; init; } = true;

    public bool Visibile { get; init; } = true;
}
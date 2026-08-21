namespace Preventivi.Web.UI.Panel;

public sealed class PFWPanelModel
{
    public string? Titolo { get; init; }

    public string? Sottotitolo { get; init; }

    public bool MostraHeader { get; init; } = true;

    public bool MostraFooter { get; init; }

    public string? Footer { get; init; }

    public string BodyHtml { get; init; } = "";
}
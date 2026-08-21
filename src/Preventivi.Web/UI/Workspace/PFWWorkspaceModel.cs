namespace Preventivi.Web.UI.Workspace;

public sealed class PFWWorkspaceModel
{
    public bool MostraToolbar { get; init; } = true;

    public bool MostraTabs { get; init; } = true;

    public bool MostraStatusBar { get; init; }

    public string ContenutoHtml { get; init; } = "";

    public string? StatusBarHtml { get; init; }
}
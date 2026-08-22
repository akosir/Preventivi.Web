namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardHeaderModel
{
    public string Titolo { get; init; } = "";

    public string? Sottotitolo { get; init; }

    public string DataTesto { get; init; } = "";

    public string? UltimoAggiornamento { get; init; }
}
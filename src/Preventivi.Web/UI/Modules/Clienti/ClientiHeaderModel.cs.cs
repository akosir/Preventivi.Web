namespace Preventivi.Web.UI.Modules.Clienti;

public sealed class ClientiHeaderModel
{
    public string Titolo { get; init; } = "";

    public string? Sottotitolo { get; init; }

    public string TestoPulsanteNuovo { get; init; } = "";

    public string UrlNuovo { get; init; } = "#";
}
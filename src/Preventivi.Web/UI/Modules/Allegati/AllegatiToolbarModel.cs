namespace Preventivi.Web.UI.Modules.Allegati;

public sealed class AllegatiToolbarModel
{
    public string TestoNuovo { get; init; } = "Nuovo Allegato";

    public string? UrlNuovo { get; init; }

    public bool MostraNuovo { get; init; } = true;

    public bool MostraAggiorna { get; init; } = true;
}
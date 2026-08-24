using Preventivi.Core.Allegati;

namespace Preventivi.Web.UI.Modules.Allegati;

public sealed class AllegatiGridModel
{
    public IReadOnlyList<AllegatoListItem> Allegati { get; init; }
        = Array.Empty<AllegatoListItem>();
}
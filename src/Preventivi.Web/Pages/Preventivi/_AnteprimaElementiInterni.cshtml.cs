using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public sealed class AnteprimaElementiInterniModel
{
    public IReadOnlyList<PreventivoRigaMaterialeItem> Materiali { get; init; }
        = Array.Empty<PreventivoRigaMaterialeItem>();

    public IReadOnlyList<PreventivoRigaLavorazioneItem> Lavorazioni { get; init; }
        = Array.Empty<PreventivoRigaLavorazioneItem>();
}

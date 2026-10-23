using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli.Righe;

public sealed record ModelloPreventivoRigaFormViewModel(
    ModelloPreventivoRigaFormModel Dati,
    IReadOnlyList<TipoRigaPreventivoItem> TipiRiga,
    IReadOnlyList<ArticoloLookupItem> Articoli,
    IReadOnlyList<ModelloCicloLookupItem> ModelliCiclo);

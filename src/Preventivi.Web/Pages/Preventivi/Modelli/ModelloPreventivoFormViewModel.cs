using Preventivi.Core.Clienti;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli;

public sealed record ModelloPreventivoFormViewModel(
    ModelloPreventivoFormModel Dati,
    IReadOnlyList<ClienteListItem> Clienti);

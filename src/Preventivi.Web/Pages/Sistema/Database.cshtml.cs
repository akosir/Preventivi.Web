using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Database;
using Preventivi.Web.Database;

namespace Preventivi.Web.Pages.Sistema;

public sealed class DatabaseModel : PageModel
{
    private readonly StatoSchemaDatabaseApplicazione _statoApplicazione;

    public DatabaseModel(
        StatoSchemaDatabaseApplicazione statoApplicazione)
    {
        _statoApplicazione = statoApplicazione;
    }

    public StatoSchemaDatabase Stato { get; private set; } =
        StatoSchemaDatabase.NonDisponibile();

    public void OnGet()
    {
        Stato = _statoApplicazione.Stato;
    }
}

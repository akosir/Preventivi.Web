using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
namespace Preventivi.Web.Pages.Amministrazione.Utenti;
public sealed class DettaglioModel(IGestioneUtentiRepository repository) : PageModel
{
    public UtenteGestione? Utente { get; private set; }
    public IReadOnlyList<UtenteAudit> Audit { get; private set; }=[];
    public async Task<IActionResult> OnGetAsync(int id,CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        try
        {
            Utente=await repository.GetDettaglioAsync(attore,id,cancellationToken); if(Utente is null) return NotFound();
            Audit=await repository.GetAuditAsync(attore,id,cancellationToken); return Page();
        }
        catch(SqlException ex) when(ex.Number==54308) { return Forbid(); }
    }
}

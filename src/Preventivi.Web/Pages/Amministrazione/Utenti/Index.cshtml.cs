using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
namespace Preventivi.Web.Pages.Amministrazione.Utenti;
public sealed class IndexModel(IGestioneUtentiRepository repository) : PageModel
{
    [BindProperty(SupportsGet=true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet=true)] public bool? Attivo { get; set; }
    public IReadOnlyList<UtenteGestione> Utenti { get; private set; }=[];
    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        if(Ricerca?.Length>150) { ModelState.AddModelError(nameof(Ricerca),"Usare al massimo 150 caratteri."); return Page(); }
        try { Utenti=await repository.GetElencoAsync(attore,Ricerca,Attivo,cancellationToken); return Page(); }
        catch(SqlException ex) when(ex.Number==54308) { return Forbid(); }
    }
}

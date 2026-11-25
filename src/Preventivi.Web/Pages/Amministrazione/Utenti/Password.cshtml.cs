using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
namespace Preventivi.Web.Pages.Amministrazione.Utenti;
public sealed class PasswordModel(IGestioneUtentiRepository repository,GestioneUtentiApplicationService service) : PageModel
{
    public UtenteGestione? Utente { get; private set; }
    [BindProperty] public string? Versione { get; set; }
    [BindProperty] public string? NuovaPassword { get; set; }
    [BindProperty] public string? ConfermaPassword { get; set; }
    public async Task<IActionResult> OnGetAsync(int id,CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        try { Utente=await repository.GetDettaglioAsync(attore,id,cancellationToken); if(Utente is null) return NotFound(); Versione=Convert.ToBase64String(Utente.VersioneRiga); return Page(); }
        catch(SqlException ex) when(ex.Number==54308) { return Forbid(); }
    }
    public async Task<IActionResult> OnPostAsync(int id,CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        try
        {
            Utente=await repository.GetDettaglioAsync(attore,id,cancellationToken); if(Utente is null) return NotFound();
            var versione=UtentiGestioneErrori.Versione(Versione,ModelState);
            if(string.IsNullOrEmpty(NuovaPassword) || NuovaPassword!=ConfermaPassword) ModelState.AddModelError(string.Empty,"Inserire la nuova password e la conferma corrispondente.");
            if(ModelState.IsValid)
            {
                await service.ReimpostaAsync(attore,Utente,versione,NuovaPassword!,cancellationToken);
                TempData["MessaggioSuccesso"]="Password reimpostata. L’utente deve accedere nuovamente.";
                return RedirectToPage("./Dettaglio",new { id });
            }
        }
        catch(ArgumentException ex) { ModelState.AddModelError(string.Empty,ex.Message); }
        catch(SqlException ex) when(UtentiGestioneErrori.Gestito(ex.Number))
        { if(ex.Number==54308) return Forbid(); ModelState.AddModelError(string.Empty,UtentiGestioneErrori.Messaggio(ex.Number)); }
        NuovaPassword=null; ConfermaPassword=null; ModelState.Remove(nameof(NuovaPassword)); ModelState.Remove(nameof(ConfermaPassword)); return Page();
    }
}

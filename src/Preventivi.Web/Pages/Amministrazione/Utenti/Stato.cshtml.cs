using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
namespace Preventivi.Web.Pages.Amministrazione.Utenti;
public sealed class StatoModel(IGestioneUtentiRepository repository,GestioneUtentiApplicationService service) : PageModel
{
    public UtenteGestione? Utente { get; private set; }
    [BindProperty] public string? Versione { get; set; }
    [BindProperty] public bool Conferma { get; set; }
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
            if(!Conferma) ModelState.AddModelError(string.Empty,"Confermare il cambio di stato.");
            if(attore.IdUtente==id && Utente.Attivo) ModelState.AddModelError(string.Empty,UtentiGestioneErrori.Messaggio(54306));
            if(!ModelState.IsValid) return Page();
            await service.SalvaAsync(attore,id,new() { Username=Utente.Username,NomeCompleto=Utente.NomeCompleto,Attivo=!Utente.Attivo,
                Ruoli=JsonSerializer.Deserialize<int[]>(Utente.RuoliJson) ?? [],VersioneRiga=versione },null,cancellationToken);
            TempData["MessaggioSuccesso"]="Stato dell’utente aggiornato.";
            return RedirectToPage("./Dettaglio",new { id });
        }
        catch(ArgumentException ex) { ModelState.AddModelError(string.Empty,ex.Message); return Page(); }
        catch(SqlException ex) when(UtentiGestioneErrori.Gestito(ex.Number))
        { if(ex.Number==54308) return Forbid(); ModelState.AddModelError(string.Empty,UtentiGestioneErrori.Messaggio(ex.Number)); return Page(); }
    }
}

using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
namespace Preventivi.Web.Pages.Amministrazione.Utenti;
public sealed class ModificaModel(IGestioneUtentiRepository repository,GestioneUtentiApplicationService service) : PageModel
{
    [BindProperty] public DatiUtente Dati { get; set; }=new();
    [BindProperty] public string? Password { get; set; }
    [BindProperty] public string? ConfermaPassword { get; set; }
    public UtenteGestione? Utente { get; private set; }
    public IReadOnlyList<RuoloGestione> Ruoli { get; private set; }=[];
    public int[] RuoliPrecedenti { get; private set; }=[];
    public async Task<IActionResult> OnGetAsync(int? id,CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        try
        {
            if(!await CaricaAsync(attore,id,cancellationToken)) return NotFound();
            if(Utente is not null) Dati=new() { Username=Utente.Username,NomeCompleto=Utente.NomeCompleto,Attivo=Utente.Attivo,Ruoli=RuoliPrecedenti,Versione=Convert.ToBase64String(Utente.VersioneRiga) };
            return Page();
        }
        catch(SqlException ex) when(ex.Number==54308) { return Forbid(); }
    }
    public async Task<IActionResult> OnPostAsync(int? id,CancellationToken cancellationToken)
    {
        var attore=GestioneUtentiApplicationService.Attore(User); if(attore is null) return Forbid();
        try
        {
            if(!await CaricaAsync(attore,id,cancellationToken)) return NotFound();
            if(Utente is not null) { Dati.Username=Utente.Username; ModelState.Remove("Dati.Username"); }
            var versione=id.HasValue ? UtentiGestioneErrori.Versione(Dati.Versione,ModelState) : [];
            if(!id.HasValue && (Password!=ConfermaPassword || string.IsNullOrEmpty(Password)))
                ModelState.AddModelError(string.Empty,"Inserire e confermare la password iniziale.");
            if(Dati.Ruoli.Length==0 || Dati.Ruoli.Any(x=>!Ruoli.Any(r=>r.IdRuolo==x && (r.Attivo || RuoliPrecedenti.Contains(x)))))
                ModelState.AddModelError("Dati.Ruoli","Selezionare almeno un ruolo disponibile.");
            if(!ModelState.IsValid) { PulisciPassword(); return Page(); }
            var risultato=await service.SalvaAsync(attore,id,new() { Username=Dati.Username,NomeCompleto=Dati.NomeCompleto,Attivo=Dati.Attivo,Ruoli=Dati.Ruoli,VersioneRiga=versione },Password,cancellationToken);
            TempData["MessaggioSuccesso"]="Utente salvato correttamente.";
            return RedirectToPage("./Dettaglio",new { id=risultato });
        }
        catch(ArgumentException ex) { ModelState.AddModelError(string.Empty,ex.Message); PulisciPassword(); return Page(); }
        catch(SqlException ex) when(UtentiGestioneErrori.Gestito(ex.Number))
        {
            if(ex.Number==54308) return Forbid();
            ModelState.AddModelError(string.Empty,UtentiGestioneErrori.Messaggio(ex.Number)); PulisciPassword(); return Page();
        }
    }
    private async Task<bool> CaricaAsync(AmministratoreOperante attore,int? id,CancellationToken cancellationToken)
    {
        if(id.HasValue) { Utente=await repository.GetDettaglioAsync(attore,id.Value,cancellationToken); if(Utente is null) return false;
            RuoliPrecedenti=JsonSerializer.Deserialize<int[]>(Utente.RuoliJson) ?? []; }
        Ruoli=await repository.GetRuoliAsync(attore,cancellationToken); return true;
    }
    private void PulisciPassword() { Password=null; ConfermaPassword=null; ModelState.Remove(nameof(Password)); ModelState.Remove(nameof(ConfermaPassword)); }
    public sealed class DatiUtente
    {
        [Required(ErrorMessage="Inserire lo username."),StringLength(50,ErrorMessage="Lo username può contenere al massimo 50 caratteri.")] public string Username { get; set; }="";
        [StringLength(150,ErrorMessage="Il nome completo può contenere al massimo 150 caratteri.")] public string? NomeCompleto { get; set; }
        public bool Attivo { get; set; }=true;
        public int[] Ruoli { get; set; }=[];
        public string? Versione { get; set; }
    }
}

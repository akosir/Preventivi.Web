using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo.Righe;

public sealed class ModificaModel(IModelloCicloRepository repository, ILogger<ModificaModel> logger) : PageModel
{
    [BindProperty] public ModelloCicloRigaFormModel Dati { get; set; } = new();
    public ModelloCicloDettaglio? ModelloCiclo { get; private set; }
    public int IdRiga { get; private set; }
    public async Task<IActionResult> OnGetAsync(int idModelloCiclo, int id, CancellationToken token)
    {
        var riga = await repository.GetRigaAsync(id, token); if (riga is null || riga.IdModelloCiclo != idModelloCiclo || !await CaricaAsync(idModelloCiclo, riga.IdLavorazione, token)) return NotFound(); IdRiga=id;
        Dati = new() { RigaNr=riga.RigaNr, Sequenza=riga.Sequenza, IdLavorazione=riga.IdLavorazione, TempoSetupMin=riga.TempoSetupMin, TempoPezzoMin=riga.TempoPezzoMin, CostoOrario=riga.CostoOrario, CostoFisso=riga.CostoFisso, Note=riga.Note, VersioneRigaBase64=Convert.ToBase64String(riga.VersioneRiga) }; return Page();
    }
    public async Task<IActionResult> OnPostAsync(int idModelloCiclo, int id, CancellationToken token)
    {
        var riga = await repository.GetRigaAsync(id, token); if (riga is null || riga.IdModelloCiclo != idModelloCiclo || !await CaricaAsync(idModelloCiclo, riga.IdLavorazione, token)) return NotFound(); IdRiga=id;
        byte[] versione; try { versione=Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); } catch(FormatException){ versione=[]; ModelState.AddModelError(string.Empty,"La versione dei dati non e valida. Ricaricare la pagina."); }
        if(!ModelState.IsValid) return Page();
        try { await repository.AggiornaRigaAsync(new ModelloCicloRigaUpdateModel { IdRigaModelloCiclo=id, IdModelloCiclo=idModelloCiclo, RigaNr=Dati.RigaNr, Sequenza=Dati.Sequenza, IdLavorazione=Dati.IdLavorazione, TempoSetupMin=Dati.TempoSetupMin, TempoPezzoMin=Dati.TempoPezzoMin, CostoOrario=Dati.CostoOrario, CostoFisso=Dati.CostoFisso, Note=Dati.Note, Utente=User.Identity?.Name ?? "Sistema", VersioneRiga=versione }, token); TempData["MessaggioSuccesso"]="Riga del modello ciclo aggiornata correttamente."; return RedirectToPage("../Dettaglio",new{id=idModelloCiclo}); }
        catch(SqlException ex) when(ModelliCicloSqlErrori.Gestito(ex.Number)){ logger.LogWarning(ex,"Aggiornamento riga modello ciclo {Id} rifiutato",id); ModelState.AddModelError(string.Empty,ModelliCicloSqlErrori.Messaggio(ex.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int id,int? corrente,CancellationToken token){ ModelloCiclo=await repository.GetDettaglioAsync(id,token); if(ModelloCiclo is null)return false; ViewData["Lavorazioni"]=await repository.GetLavorazioniAsync(corrente,token); return true; }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo.Righe;

public sealed class EliminaModel(IModelloCicloRepository repository, ILogger<EliminaModel> logger) : PageModel
{
    public ModelloCicloDettaglio? ModelloCiclo { get; private set; }
    public ModelloCicloRigaDettaglio? Riga { get; private set; }
    public async Task<IActionResult> OnGetAsync(int idModelloCiclo,int id,CancellationToken token)=>await CaricaAsync(idModelloCiclo,id,token)?Page():NotFound();
    public async Task<IActionResult> OnPostAsync(int idModelloCiclo,int id,string versioneRigaBase64,CancellationToken token)
    {
        if(!await CaricaAsync(idModelloCiclo,id,token))return NotFound(); byte[] versione;
        try{versione=Convert.FromBase64String(versioneRigaBase64);}catch(FormatException){ModelState.AddModelError(string.Empty,"La versione dei dati non e valida. Ricaricare la pagina.");return Page();}
        try{await repository.EliminaRigaAsync(new ModelloCicloRigaDeleteModel{IdRigaModelloCiclo=id,IdModelloCiclo=idModelloCiclo,VersioneRiga=versione},token);TempData["MessaggioSuccesso"]="Riga del modello ciclo eliminata correttamente.";return RedirectToPage("../Dettaglio",new{id=idModelloCiclo});}
        catch(SqlException ex)when(ModelliCicloSqlErrori.Gestito(ex.Number)){logger.LogWarning(ex,"Eliminazione riga modello ciclo {Id} rifiutata",id);ModelState.AddModelError(string.Empty,ModelliCicloSqlErrori.Messaggio(ex.Number));return Page();}
    }
    private async Task<bool> CaricaAsync(int idModelloCiclo,int id,CancellationToken token){ModelloCiclo=await repository.GetDettaglioAsync(idModelloCiclo,token);Riga=await repository.GetRigaAsync(id,token);return ModelloCiclo is not null&&Riga is not null&&Riga.IdModelloCiclo==idModelloCiclo;}
}

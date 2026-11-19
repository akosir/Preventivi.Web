using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.ModelliCiclo;

public sealed class DettaglioModel(IModelloCicloRepository repository, IAllegatoRepository allegatoRepository, ILogger<DettaglioModel> logger) : PageModel
{
    public ModelloCicloDettaglio? ModelloCiclo { get; private set; }
    public IReadOnlyList<ModelloCicloRigaListItem> Righe { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) => await CaricaAsync(id, cancellationToken) ? Page() : NotFound();
    public Task<IActionResult> OnPostAttivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) => ImpostaStatoAsync(id, true, versioneRigaBase64, cancellationToken);
    public Task<IActionResult> OnPostDisattivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) => ImpostaStatoAsync(id, false, versioneRigaBase64, cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(int id, bool attivo, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        byte[] versione; try { versione = Convert.FromBase64String(versioneRigaBase64); } catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); await CaricaAsync(id, cancellationToken); return Page(); }
        try
        {
            await repository.ImpostaStatoAsync(new AnagraficaProduttivaStatoModel { Id = id, Attivo = attivo, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken);
            TempData["MessaggioSuccesso"] = attivo ? "Modello ciclo riattivato correttamente." : "Modello ciclo disattivato correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException ex) when (ModelliCicloSqlErrori.Gestito(ex.Number)) { logger.LogWarning(ex, "Cambio stato modello ciclo {Id} rifiutato", id); ModelState.AddModelError(string.Empty, ModelliCicloSqlErrori.Messaggio(ex.Number)); await CaricaAsync(id, cancellationToken); return Page(); }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        ModelloCiclo = await repository.GetDettaglioAsync(id, cancellationToken); if (ModelloCiclo is null) return false;
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        Allegati = new AllegatiGridModel { Allegati = await allegatoRepository.GetElencoAsync(AllegatoEntita.ModelliCiclo, id, cancellationToken), ReturnUrl = Url.Page("/Anagrafiche/ModelliCiclo/Dettaglio", new { id }) };
        return true;
    }
}

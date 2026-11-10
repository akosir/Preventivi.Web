using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Lavorazioni;

public sealed class EliminaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository; private readonly ILogger<EliminaModel> _logger;
    public EliminaModel(IDistintaBaseRepository repository, ILogger<EliminaModel> logger) { _repository = repository; _logger = logger; }
    public DistintaLavorazioneDettaglio? Lavorazione { get; private set; }
    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) => await CaricaAsync(id, cancellationToken) ? Page() : NotFound();
    public async Task<IActionResult> OnPostAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound(); byte[] versione; try { versione = Convert.FromBase64String(versioneRigaBase64); } catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return Page(); }
        try { await _repository.EliminaLavorazioneAsync(new DistintaElementoDeleteModel { Id = id, VersioneRiga = versione }, cancellationToken); TempData["MessaggioSuccesso"] = "Lavorazione rimossa dalla distinta."; return RedirectToPage("../Nodi/Dettaglio", new { id = Lavorazione!.IdNodoDistinta }); }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number)) { _logger.LogWarning(exception, "Eliminazione lavorazione distinta {Id} rifiutata", id); ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken) { if (id <= 0) return false; Lavorazione = await _repository.GetLavorazioneAsync(id, cancellationToken); return Lavorazione is not null; }
}

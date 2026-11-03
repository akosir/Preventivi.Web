using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Lavorazioni;

public sealed class DettaglioModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    private readonly ILogger<DettaglioModel> _logger;

    public DettaglioModel(IAnagraficheProduttiveRepository repository, ILogger<DettaglioModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public LavorazioneDettaglio? Lavorazione { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ? Page() : NotFound();

    public Task<IActionResult> OnPostAttivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, true, versioneRigaBase64, cancellationToken);

    public Task<IActionResult> OnPostDisattivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, false, versioneRigaBase64, cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(int id, bool attiva, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        byte[] versione;
        try { versione = Convert.FromBase64String(versioneRigaBase64); }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
            await CaricaAsync(id, cancellationToken);
            return Page();
        }

        try
        {
            await _repository.ImpostaStatoLavorazioneAsync(new AnagraficaProduttivaStatoModel
            {
                Id = id,
                Attivo = attiva,
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = attiva ? "Lavorazione riattivata correttamente." : "Lavorazione disattivata correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException exception) when (AnagraficheProduttiveSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Cambio stato lavorazione {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, AnagraficheProduttiveSqlErrori.Messaggio(exception.Number));
            await CaricaAsync(id, cancellationToken);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Lavorazione = await _repository.GetLavorazioneAsync(id, cancellationToken);
        return Lavorazione is not null;
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

public sealed class DettaglioModel : PageModel
{
    private readonly IArticoloRepository _repository;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<DettaglioModel> _logger;

    public DettaglioModel(IArticoloRepository repository, IAllegatoRepository allegatoRepository, ILogger<DettaglioModel> logger)
    {
        _repository = repository;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public ArticoloDettaglio? Articolo { get; private set; }
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ? Page() : NotFound();

    public Task<IActionResult> OnPostAttivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, true, versioneRigaBase64, cancellationToken);

    public Task<IActionResult> OnPostDisattivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, false, versioneRigaBase64, cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(int id, bool attivo, string versioneRigaBase64, CancellationToken cancellationToken)
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
            await _repository.ImpostaStatoAsync(new AnagraficaProduttivaStatoModel
            {
                Id = id,
                Attivo = attivo,
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = attivo ? "Articolo riattivato correttamente." : "Articolo disattivato correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException exception) when (ArticoliSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Cambio stato articolo {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, ArticoliSqlErrori.Messaggio(exception.Number));
            await CaricaAsync(id, cancellationToken);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Articolo = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Articolo is null) return false;
        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(AllegatoEntita.Articoli, id, cancellationToken),
            ReturnUrl = Url.Page("/Anagrafiche/Articoli/Dettaglio", new { id })
        };
        return true;
    }
}

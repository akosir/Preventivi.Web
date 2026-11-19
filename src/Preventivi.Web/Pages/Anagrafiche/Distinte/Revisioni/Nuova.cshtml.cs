using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni;

public sealed class NuovaModel : PageModel
{
    private readonly IArticoloRepository _articoli;
    private readonly IDistintaBaseRepository _repository;
    private readonly IDistintaBaseApplicationService _applicationService;
    private readonly ILogger<NuovaModel> _logger;

    public NuovaModel(
        IArticoloRepository articoli,
        IDistintaBaseRepository repository,
        IDistintaBaseApplicationService applicationService,
        ILogger<NuovaModel> logger)
    {
        _articoli = articoli;
        _repository = repository;
        _applicationService = applicationService;
        _logger = logger;
    }

    [BindProperty]
    public DistintaRevisioneFormModel Dati { get; set; } = new();

    public ArticoloDettaglio? Articolo { get; private set; }
    public DistintaRevisioneDettaglio? Sorgente { get; private set; }

    public async Task<IActionResult> OnGetAsync(
        int idArticolo,
        int? idSorgente,
        CancellationToken cancellationToken) =>
        await CaricaAsync(idArticolo, idSorgente, cancellationToken)
            ? Page()
            : NotFound();

    public async Task<IActionResult> OnPostAsync(
        int idArticolo,
        int? idSorgente,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idArticolo, idSorgente, cancellationToken))
        {
            return NotFound();
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var utente = User.Identity?.Name ?? "Sistema";
            var idRevisione = idSorgente.HasValue
                ? await _applicationService.DuplicaAsync(
                    new DistintaRevisioneDuplicazioneRequest
                    {
                        IdRevisioneSorgente = idSorgente.Value,
                        IdArticoloDestinazione = idArticolo,
                        Note = Dati.Note,
                        Utente = utente
                    },
                    cancellationToken)
                : await _applicationService.CreaBozzaAsync(
                    new DistintaRevisioneCreateModel
                    {
                        IdArticolo = idArticolo,
                        Note = Dati.Note,
                        Utente = utente
                    },
                    cancellationToken);

            TempData["MessaggioSuccesso"] = idSorgente.HasValue
                ? "Nuova revisione duplicata correttamente."
                : "Distinta corrente creata.";
            return RedirectToPage("../Dettaglio", new { idArticolo, idRevisione });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione revisione distinta rifiutata");
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
        catch (DistintaBaseApplicationException exception)
        {
            _logger.LogError(exception, "Duplicazione revisione distinta non riuscita");
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(
        int idArticolo,
        int? idSorgente,
        CancellationToken cancellationToken)
    {
        if (idArticolo <= 0)
        {
            return false;
        }

        Articolo = await _articoli.GetDettaglioAsync(idArticolo, cancellationToken);
        if (Articolo is null)
        {
            return false;
        }

        var revisioni = await _repository.GetRevisioniAsync(idArticolo, cancellationToken);
        if (idSorgente.HasValue)
        {
            Sorgente = await _repository.GetRevisioneAsync(idSorgente.Value, cancellationToken);
            return false;
        }

        return revisioni.All(x => !x.Modificabile);
    }
}

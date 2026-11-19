using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni;

public sealed class DuplicaModel : PageModel
{
    private readonly IArticoloRepository _articoli;
    private readonly IDistintaBaseRepository _repository;
    private readonly IDistintaBaseApplicationService _applicationService;
    private readonly ILogger<DuplicaModel> _logger;

    public DuplicaModel(
        IArticoloRepository articoli,
        IDistintaBaseRepository repository,
        IDistintaBaseApplicationService applicationService,
        ILogger<DuplicaModel> logger)
    {
        _articoli = articoli;
        _repository = repository;
        _applicationService = applicationService;
        _logger = logger;
    }

    [BindProperty]
    public DistintaRevisioneDuplicazioneFormModel Dati { get; set; } = new();

    public DistintaRevisioneDettaglio? Sorgente { get; private set; }
    public IReadOnlyList<ArticoloListItem> Articoli { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(int idSorgente, CancellationToken cancellationToken) =>
        await CaricaAsync(idSorgente, cancellationToken) ? Page() : NotFound();

    public async Task<IActionResult> OnPostAsync(int idSorgente, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idSorgente, cancellationToken))
        {
            return NotFound();
        }

        if (Dati.IdArticoloDestinazione.HasValue && !Articoli.Any(x => x.IdArticolo == Dati.IdArticoloDestinazione.Value))
        {
            ModelState.AddModelError(nameof(Dati.IdArticoloDestinazione), "L'articolo di destinazione non e valido o non e attivo.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var idRevisione = await _applicationService.DuplicaAsync(
                new DistintaRevisioneDuplicazioneRequest
                {
                    IdRevisioneSorgente = idSorgente,
                    IdArticoloDestinazione = Dati.IdArticoloDestinazione!.Value,
                    Note = Dati.Note,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = "Distinta duplicata sul nuovo articolo con file allegati indipendenti.";
            return RedirectToPage("../Dettaglio", new { idArticolo = Dati.IdArticoloDestinazione.Value, idRevisione });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Duplicazione distinta rifiutata");
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
        catch (DistintaBaseApplicationException exception)
        {
            _logger.LogError(exception, "Duplicazione distinta non riuscita");
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idSorgente, CancellationToken cancellationToken)
    {
        if (idSorgente <= 0)
        {
            return false;
        }

        Sorgente = await _repository.GetRevisioneAsync(idSorgente, cancellationToken);
        if (Sorgente is null || !Sorgente.Modificabile || Sorgente.NumeroNodi == 0)
        {
            return false;
        }

        var articoliConDistinta = (await _repository.GetArticoliAsync(cancellationToken: cancellationToken))
            .Where(x => x.IdRevisionePubblicata.HasValue)
            .Select(x => x.IdArticolo)
            .ToHashSet();
        Articoli = (await _articoli.GetElencoAsync(
            soloAttivi: true,
            cancellationToken: cancellationToken))
            .Where(x => x.IdArticolo != Sorgente.IdArticolo && !articoliConDistinta.Contains(x.IdArticolo))
            .ToArray();
        return true;
    }
}

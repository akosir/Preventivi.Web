using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class AdeguamentoEliminaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<AdeguamentoEliminaModel> _logger;

    public AdeguamentoEliminaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        IAllegatoRepository allegatoRepository,
        ILogger<AdeguamentoEliminaModel> logger)
    {
        _repository = repository;
        _service = service;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaAdeguamentoDettaglio? Adeguamento { get; private set; }
    public bool HaAllegati { get; private set; }

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    [BindProperty]
    public string VersioneRilievoBase64 { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        VersioneRigaBase64 = Convert.ToBase64String(Adeguamento!.VersioneRiga);
        VersioneRilievoBase64 = Convert.ToBase64String(Adeguamento.VersioneRilievo);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (Adeguamento!.Applicato || Adeguamento.IdVarianteGenerata.HasValue || HaAllegati)
        {
            ModelState.AddModelError(
                string.Empty,
                Adeguamento.Applicato
                    ? "Un adeguamento applicato non puo essere eliminato."
                    : Adeguamento.IdVarianteGenerata.HasValue
                        ? "Annullare prima la preparazione della variante generata."
                    : "Eliminare prima gli allegati collegati all'adeguamento.");
            return Page();
        }

        byte[] versione;
        byte[] versioneRilievo;
        try
        {
            versione = Convert.FromBase64String(VersioneRigaBase64);
            versioneRilievo = Convert.FromBase64String(VersioneRilievoBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione dei dati non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.EliminaAdeguamentoAsync(
                new CampionaturaAdeguamentoDeleteModel
                {
                    IdAdeguamento = id,
                    VersioneRiga = versione,
                    VersioneRilievo = versioneRilievo,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Adeguamento eliminato correttamente.";
            return RedirectToPage("./Dettaglio", new { id = idCampionatura });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52720 and <= 52739)
        {
            _logger.LogWarning(exception, "Eliminazione adeguamento rifiutata");
            ModelState.AddModelError(string.Empty, MessaggiSqlCampionature.Per(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (idCampionatura <= 0 || id <= 0)
            return false;

        Campionatura = await _repository.GetDettaglioAsync(idCampionatura, cancellationToken);
        Adeguamento = await _repository.GetAdeguamentoAsync(id, cancellationToken);
        if (Campionatura is null || Adeguamento?.IdCampionatura != idCampionatura)
            return false;

        HaAllegati = (await _allegatoRepository.GetElencoAsync(
            AllegatoEntita.CampionatureAdeguamenti,
            id,
            cancellationToken)).Count > 0;
        return true;
    }
}

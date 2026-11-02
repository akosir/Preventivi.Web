using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages.Campionature;

[Authorize(Policy = AutorizzazioneApplicazione.PolicyPreventivi)]
public sealed class AdeguamentoConfermaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<AdeguamentoConfermaModel> _logger;

    public AdeguamentoConfermaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<AdeguamentoConfermaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaAdeguamentoDettaglio? Adeguamento { get; private set; }

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    [BindProperty]
    public string VersioneRilievoBase64 { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (Adeguamento!.Applicato || !Adeguamento.IdVarianteGenerata.HasValue)
        {
            TempData["MessaggioErrore"] = "L'adeguamento non puo essere confermato nello stato corrente.";
            return RedirectToPage("./AdeguamentoDettaglio", new { idCampionatura, id });
        }

        VersioneRigaBase64 = Convert.ToBase64String(Adeguamento.VersioneRiga);
        VersioneRilievoBase64 = Convert.ToBase64String(Adeguamento.VersioneRilievo);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (Adeguamento!.Applicato || !Adeguamento.IdVarianteGenerata.HasValue)
        {
            ModelState.AddModelError(string.Empty, "L'adeguamento non puo essere confermato nello stato corrente.");
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
            await _service.ConfermaAdeguamentoAsync(
                new CampionaturaAdeguamentoConfermaModel
                {
                    IdAdeguamento = id,
                    VersioneRiga = versione,
                    VersioneRilievo = versioneRilievo,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Applicazione dell'adeguamento confermata correttamente.";
            return RedirectToPage("./AdeguamentoDettaglio", new { idCampionatura, id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52740 and <= 52759)
        {
            _logger.LogWarning(exception, "Conferma applicazione adeguamento rifiutata");
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
        return Campionatura is not null && Adeguamento?.IdCampionatura == idCampionatura;
    }
}

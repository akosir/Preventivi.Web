using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class AdeguamentoNuovoModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<AdeguamentoNuovoModel> _logger;

    public AdeguamentoNuovoModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<AdeguamentoNuovoModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaRilievoDettaglio? Rilievo { get; private set; }

    [BindProperty]
    public CampionaturaAdeguamentoFormModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idCampionatura,
        int idRilievo,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, idRilievo, cancellationToken))
            return NotFound();

        Dati = new CampionaturaAdeguamentoFormModel
        {
            DescrizioneAdeguamento = Rilievo!.SoluzioneProposta ?? string.Empty,
            VersioneRilievoBase64 = Convert.ToBase64String(Rilievo.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idCampionatura,
        int idRilievo,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, idRilievo, cancellationToken))
            return NotFound();

        if (!ModelState.IsValid)
            return Page();

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(Dati.VersioneRilievoBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione del rilievo non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.CreaAdeguamentoAsync(
                new CampionaturaAdeguamentoCreateModel
                {
                    IdRilievoCampionatura = idRilievo,
                    DescrizioneAdeguamento = Dati.DescrizioneAdeguamento,
                    ImpattoCostoStimato = Dati.ImpattoCostoStimato,
                    ImpattoVenditaStimato = Dati.ImpattoVenditaStimato,
                    Note = Dati.Note,
                    VersioneRilievo = versione,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Adeguamento registrato senza modificare il preventivo.";
            return RedirectToPage("./Dettaglio", new { id = idCampionatura });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52700 and <= 52719)
        {
            _logger.LogWarning(exception, "Creazione adeguamento rifiutata");
            ModelState.AddModelError(string.Empty, MessaggiSqlCampionature.Per(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(
        int idCampionatura,
        int idRilievo,
        CancellationToken cancellationToken)
    {
        if (idCampionatura <= 0 || idRilievo <= 0)
            return false;

        Campionatura = await _repository.GetDettaglioAsync(idCampionatura, cancellationToken);
        Rilievo = await _repository.GetRilievoAsync(idRilievo, cancellationToken);
        return Campionatura is not null && Rilievo?.IdCampionatura == idCampionatura;
    }
}

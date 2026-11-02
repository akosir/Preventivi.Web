using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class AdeguamentoModificaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<AdeguamentoModificaModel> _logger;

    public AdeguamentoModificaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<AdeguamentoModificaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaAdeguamentoDettaglio? Adeguamento { get; private set; }

    [BindProperty]
    public CampionaturaAdeguamentoFormModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (Adeguamento!.Applicato)
        {
            TempData["MessaggioErrore"] = "Un adeguamento applicato non puo essere modificato.";
            return RedirectToPage("./AdeguamentoDettaglio", new { idCampionatura, id });
        }

        Dati = new CampionaturaAdeguamentoFormModel
        {
            DescrizioneAdeguamento = Adeguamento.DescrizioneAdeguamento,
            ImpattoCostoStimato = Adeguamento.ImpattoCostoStimato,
            ImpattoVenditaStimato = Adeguamento.ImpattoVenditaStimato,
            Note = Adeguamento.Note,
            VersioneRigaBase64 = Convert.ToBase64String(Adeguamento.VersioneRiga),
            VersioneRilievoBase64 = Convert.ToBase64String(Adeguamento.VersioneRilievo)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (!ModelState.IsValid)
            return Page();

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(Dati.VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione dell'adeguamento non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.AggiornaAdeguamentoAsync(
                new CampionaturaAdeguamentoUpdateModel
                {
                    IdAdeguamento = id,
                    DescrizioneAdeguamento = Dati.DescrizioneAdeguamento,
                    ImpattoCostoStimato = Dati.ImpattoCostoStimato,
                    ImpattoVenditaStimato = Dati.ImpattoVenditaStimato,
                    Note = Dati.Note,
                    VersioneRiga = versione,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Adeguamento modificato correttamente.";
            return RedirectToPage("./AdeguamentoDettaglio", new { idCampionatura, id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52720 and <= 52739)
        {
            _logger.LogWarning(exception, "Modifica adeguamento rifiutata");
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

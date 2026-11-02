using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class RilievoEliminaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<RilievoEliminaModel> _logger;

    public RilievoEliminaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        IAllegatoRepository allegatoRepository,
        ILogger<RilievoEliminaModel> logger)
    {
        _repository = repository;
        _service = service;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaRilievoDettaglio? Rilievo { get; private set; }
    public bool Eliminabile { get; private set; }
    public bool HaAllegati { get; private set; }

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        VersioneRigaBase64 = Convert.ToBase64String(Rilievo!.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idCampionatura, int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (!Eliminabile)
        {
            ModelState.AddModelError(string.Empty, "Il rilievo non soddisfa le condizioni per l'eliminazione.");
            return Page();
        }

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione del rilievo non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.EliminaRilievoAsync(
                new CampionaturaRilievoDeleteModel
                {
                    IdRilievoCampionatura = id,
                    VersioneRiga = versione
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Rilievo eliminato correttamente.";
            return RedirectToPage("./Dettaglio", new { id = idCampionatura });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52720 and <= 52739)
        {
            _logger.LogWarning(exception, "Eliminazione rilievo rifiutata");
            ModelState.AddModelError(string.Empty, MessaggiSqlCampionature.Per(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idCampionatura, int idRilievo, CancellationToken cancellationToken)
    {
        if (idCampionatura <= 0 || idRilievo <= 0)
            return false;

        Campionatura = await _repository.GetDettaglioAsync(idCampionatura, cancellationToken);
        Rilievo = await _repository.GetRilievoAsync(idRilievo, cancellationToken);
        if (Campionatura is null || Rilievo?.IdCampionatura != idCampionatura)
            return false;

        var adeguamenti = await _repository.GetAdeguamentiAsync(idCampionatura, cancellationToken);
        HaAllegati = (await _allegatoRepository.GetElencoAsync(
            AllegatoEntita.CampionatureRilievi,
            idRilievo,
            cancellationToken)).Count > 0;
        Eliminabile = Rilievo.Stato == "Aperto" &&
            !HaAllegati &&
            adeguamenti.All(elemento => elemento.IdRilievoCampionatura != idRilievo);
        return true;
    }
}

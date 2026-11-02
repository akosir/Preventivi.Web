using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Campionature;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Campionature;

public sealed class RilievoDettaglioModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<RilievoDettaglioModel> _logger;

    public RilievoDettaglioModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        IAllegatoRepository allegatoRepository,
        ILogger<RilievoDettaglioModel> logger)
    {
        _repository = repository;
        _service = service;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaRilievoDettaglio? Rilievo { get; private set; }
    public IReadOnlyList<CampionaturaAdeguamentoListItem> Adeguamenti { get; private set; } = [];
    public IReadOnlyList<CampionaturaRilievoCorrezioneStatoListItem> CorrezioniStato { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();
    public IReadOnlyList<string> StatiSelezionabili { get; private set; } = [];
    public bool IsAmministratore { get; private set; }
    public bool PuoCambiareStato => IsAmministratore || StatiSelezionabili.Count > 0;

    [BindProperty]
    public string Stato { get; set; } = string.Empty;

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    [BindProperty]
    public string? MotivazioneCorrezione { get; set; }

    public async Task<IActionResult> OnGetAsync(
        int idCampionatura,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        Stato = string.Empty;
        VersioneRigaBase64 = Convert.ToBase64String(Rilievo!.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idCampionatura,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (!CampionaturaRilievoValori.Stati.Contains(Stato))
        {
            ModelState.AddModelError(nameof(Stato), "Selezionare un nuovo stato valido.");
            return Page();
        }

        var correzioneAmministrativa =
            !CampionaturaRilievoValori.TransizioneOrdinariaConsentita(Rilievo!.Stato, Stato);

        if (correzioneAmministrativa && !IsAmministratore)
        {
            ModelState.AddModelError(nameof(Stato), "La transizione selezionata non e consentita.");
            return Page();
        }

        if (correzioneAmministrativa && string.IsNullOrWhiteSpace(MotivazioneCorrezione))
        {
            ModelState.AddModelError(
                nameof(MotivazioneCorrezione),
                "Inserire la motivazione della correzione amministrativa.");
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
            await _service.AggiornaStatoRilievoAsync(
                new CampionaturaRilievoStatoUpdateModel
                {
                    IdRilievoCampionatura = id,
                    Stato = Stato,
                    VersioneRiga = versione,
                    Utente = User.Identity?.Name ?? "Sistema",
                    Amministratore = IsAmministratore,
                    MotivazioneCorrezione = correzioneAmministrativa
                        ? MotivazioneCorrezione
                        : null
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Stato del rilievo aggiornato correttamente.";
            return RedirectToPage(new { idCampionatura, id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52700 and <= 52739)
        {
            _logger.LogWarning(exception, "Aggiornamento stato rilievo rifiutato");
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
        if (Campionatura is null || Rilievo?.IdCampionatura != idCampionatura)
            return false;

        Adeguamenti = await _repository.GetAdeguamentiAsync(idCampionatura, cancellationToken);
        CorrezioniStato = await _repository.GetCorrezioniStatoRilievoAsync(
            idRilievo,
            cancellationToken);
        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(
                AllegatoEntita.CampionatureRilievi,
                idRilievo,
                cancellationToken)
        };
        IsAmministratore = User.IsInRole(AutorizzazioneApplicazione.RuoloAdmin);
        StatiSelezionabili = IsAmministratore
            ? CampionaturaRilievoValori.Stati
                .Where(stato => !string.Equals(stato, Rilievo.Stato, StringComparison.Ordinal))
                .ToArray()
            : CampionaturaRilievoValori.StatiDestinazioneOrdinaria(Rilievo.Stato);
        return true;
    }
}

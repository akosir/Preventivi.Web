using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class RilievoModificaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<RilievoModificaModel> _logger;

    public RilievoModificaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<RilievoModificaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaRilievoDettaglio? Rilievo { get; private set; }
    public IReadOnlyList<CampionaturaTipoProblematicaLookupItem> Tipi { get; private set; } = [];
    public IReadOnlyList<CampionaturaProblematicaStandardLookupItem> Problematiche { get; private set; } = [];

    [BindProperty]
    public CampionaturaRilievoFormModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idCampionatura,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        if (CampionaturaRilievoValori.StatoFinale(Rilievo!.Stato))
        {
            TempData["MessaggioErrore"] = "Un rilievo concluso non puo essere modificato.";
            return RedirectToPage("./RilievoDettaglio", new { idCampionatura, id });
        }

        Dati = new CampionaturaRilievoFormModel
        {
            DataRilevazione = Rilievo.DataRilevazione,
            IdTipoProblematica = Rilievo.IdTipoProblematica,
            IdProblematicaStandard = Rilievo.IdProblematicaStandard,
            DescrizioneProblema = Rilievo.DescrizioneProblema,
            Gravita = Rilievo.Gravita,
            CausaPresunta = Rilievo.CausaPresunta,
            SoluzioneProposta = Rilievo.SoluzioneProposta,
            RichiedeNuovoCampione = Rilievo.RichiedeNuovoCampione,
            NoteCliente = Rilievo.NoteCliente,
            NoteInterne = Rilievo.NoteInterne,
            VersioneRigaBase64 = Convert.ToBase64String(Rilievo.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idCampionatura,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, id, cancellationToken))
            return NotFound();

        ValidaLookup();
        if (!ModelState.IsValid)
            return Page();

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(Dati.VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione del rilievo non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.AggiornaRilievoAsync(
                new CampionaturaRilievoUpdateModel
                {
                    IdRilievoCampionatura = id,
                    IdCampionatura = idCampionatura,
                    DataRilevazione = Dati.DataRilevazione.GetValueOrDefault(),
                    IdTipoProblematica = Dati.IdTipoProblematica,
                    IdProblematicaStandard = Dati.IdProblematicaStandard,
                    DescrizioneProblema = Dati.DescrizioneProblema,
                    Gravita = Dati.Gravita,
                    CausaPresunta = Dati.CausaPresunta,
                    SoluzioneProposta = Dati.SoluzioneProposta,
                    RichiedeNuovoCampione = Dati.RichiedeNuovoCampione,
                    NoteCliente = Dati.NoteCliente,
                    NoteInterne = Dati.NoteInterne,
                    VersioneRiga = versione,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Rilievo modificato correttamente.";
            return RedirectToPage("./RilievoDettaglio", new { idCampionatura, id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52720 and <= 52739)
        {
            _logger.LogWarning(exception, "Modifica rilievo rifiutata");
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

        Tipi = await _repository.GetTipiProblematicheAsync(cancellationToken);
        Problematiche = await _repository.GetProblematicheStandardAsync(cancellationToken);
        return true;
    }

    private void ValidaLookup()
    {
        if (Tipi.All(tipo => tipo.IdTipoProblematica != Dati.IdTipoProblematica))
            ModelState.AddModelError("Dati.IdTipoProblematica", "Selezionare un tipo di problematica attivo.");

        if (Dati.IdProblematicaStandard.HasValue && Problematiche.All(problematica =>
                problematica.IdProblematicaStandard != Dati.IdProblematicaStandard ||
                problematica.IdTipoProblematica != Dati.IdTipoProblematica))
        {
            ModelState.AddModelError(
                "Dati.IdProblematicaStandard",
                "La problematica standard deve appartenere al tipo selezionato.");
        }
    }
}

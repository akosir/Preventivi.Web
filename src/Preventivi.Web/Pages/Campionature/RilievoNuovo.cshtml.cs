using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public sealed class RilievoNuovoModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<RilievoNuovoModel> _logger;

    public RilievoNuovoModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<RilievoNuovoModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public IReadOnlyList<CampionaturaTipoProblematicaLookupItem> Tipi { get; private set; } = [];
    public IReadOnlyList<CampionaturaProblematicaStandardLookupItem> Problematiche { get; private set; } = [];

    [BindProperty]
    public CampionaturaRilievoFormModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idCampionatura,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, cancellationToken))
            return NotFound();

        Dati.DataRilevazione = DateOnly.FromDateTime(DateTime.Today);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idCampionatura,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idCampionatura, cancellationToken))
            return NotFound();

        ValidaLookup();
        if (!ModelState.IsValid)
            return Page();

        try
        {
            var idRilievo = await _service.CreaRilievoAsync(
                new CampionaturaRilievoCreateModel
                {
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
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Rilievo creato correttamente.";
            return RedirectToPage(
                "./RilievoDettaglio",
                new { idCampionatura, id = idRilievo });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52700 and <= 52719)
        {
            _logger.LogWarning(exception, "Creazione rilievo rifiutata");
            ModelState.AddModelError(string.Empty, MessaggiSqlCampionature.Per(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idCampionatura, CancellationToken cancellationToken)
    {
        if (idCampionatura <= 0)
            return false;

        Campionatura = await _repository.GetDettaglioAsync(idCampionatura, cancellationToken);
        if (Campionatura is null)
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

internal static class MessaggiSqlCampionature
{
    public static string Per(int numero) => numero switch
    {
        52702 => "La campionatura non esiste.",
        52703 => "Il tipo di problematica non esiste o non e attivo.",
        52704 => "La problematica standard non appartiene al tipo selezionato o non e attiva.",
        52705 => "Non e stato possibile assegnare il numero del rilievo. Riprovare.",
        52708 => "Il rilievo e stato modificato da un altro utente. Ricaricare la pagina.",
        52709 => "Il rilievo e gia concluso e non puo essere modificato.",
        52720 => "Compilare tutti i dati obbligatori.",
        52721 => "Il tipo di problematica non esiste o non e attivo.",
        52722 => "La problematica standard non appartiene al tipo selezionato o non e attiva.",
        52723 => "Il rilievo non esiste.",
        52724 => "Il rilievo e stato modificato da un altro utente. Ricaricare la pagina.",
        52725 => "Un rilievo concluso o respinto non puo essere modificato.",
        52726 => "Il rilievo puo essere eliminato solo quando e aperto.",
        52727 => "Il rilievo contiene adeguamenti e non puo essere eliminato.",
        52728 => "Compilare la descrizione dell'adeguamento.",
        52729 => "L'adeguamento non esiste.",
        52730 => "L'adeguamento e stato modificato da un altro utente. Ricaricare la pagina.",
        52731 => "Un adeguamento applicato costituisce storico e non puo essere modificato o eliminato.",
        52734 => "La transizione di stato selezionata non e consentita.",
        52735 => "La correzione amministrativa richiede una motivazione.",
        52736 => "Il rilievo contiene allegati. Eliminarli prima di eliminare il rilievo.",
        52737 => "L'adeguamento contiene allegati. Eliminarli prima di eliminare l'adeguamento.",
        52740 => "L'adeguamento non esiste.",
        52741 => "L'adeguamento e stato modificato da un altro utente. Ricaricare la pagina.",
        52742 => "L'adeguamento e gia applicato e costituisce storico.",
        52743 => "Esiste gia una variante preparata per questo adeguamento.",
        52744 => "L'adeguamento non e collegato a un preventivo.",
        52745 => "La variante origine non e disponibile o non appartiene al preventivo.",
        52746 => "Il codice variante indicato esiste gia per questo preventivo.",
        52747 => "La variante preparata non e disponibile.",
        52748 => "Il rilievo deve essere in Soluzione Proposta per confermare l'applicazione.",
        52749 => "Il rilievo e stato modificato da un altro utente. Ricaricare la pagina.",
        52750 => "Non esiste una preparazione da annullare.",
        52751 => "Annullare prima la variante preparata per eliminare l'adeguamento.",
        _ => "I dati non sono validi. Controllare i campi e riprovare."
    };
}

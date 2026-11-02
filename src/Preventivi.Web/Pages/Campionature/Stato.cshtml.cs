using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.Sicurezza;

namespace Preventivi.Web.Pages.Campionature;

public sealed class StatoModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<StatoModel> _logger;

    public StatoModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<StatoModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public IReadOnlyList<string> StatiSelezionabili { get; private set; } = [];
    public bool IsAmministratore { get; private set; }

    [BindProperty]
    public string Stato { get; set; } = string.Empty;

    [BindProperty]
    public DateOnly? DataConsegnaCampione { get; set; }

    [BindProperty]
    public string? Esito { get; set; }

    [BindProperty]
    public string? MotivazioneCorrezione { get; set; }

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken))
            return NotFound();

        DataConsegnaCampione = Campionatura!.DataConsegnaCampione;
        Esito = Campionatura.Esito;
        VersioneRigaBase64 = Convert.ToBase64String(Campionatura.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken))
            return NotFound();

        if (!CampionaturaValori.Stati.Contains(Stato) || Stato == Campionatura!.Stato)
        {
            ModelState.AddModelError(nameof(Stato), "Selezionare un nuovo stato valido.");
            return Page();
        }

        var correzioneAmministrativa =
            !CampionaturaValori.TransizioneOrdinariaConsentita(Campionatura.Stato, Stato);

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

        NormalizzaDatiWorkflow();
        if (!ModelState.IsValid)
            return Page();

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "Versione della campionatura non valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _service.AggiornaStatoAsync(
                new CampionaturaStatoUpdateModel
                {
                    IdCampionatura = id,
                    Stato = Stato,
                    DataConsegnaCampione = DataConsegnaCampione,
                    Esito = Esito,
                    VersioneRiga = versione,
                    Utente = User.Identity?.Name ?? "Sistema",
                    Amministratore = IsAmministratore,
                    MotivazioneCorrezione = correzioneAmministrativa
                        ? MotivazioneCorrezione
                        : null
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Stato della campionatura aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52620 and <= 52639)
        {
            _logger.LogWarning(exception, "Aggiornamento stato campionatura {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, MessaggioSql(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
            return false;

        Campionatura = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Campionatura is null)
            return false;

        IsAmministratore = User.IsInRole(AutorizzazioneApplicazione.RuoloAdmin);
        StatiSelezionabili = IsAmministratore
            ? CampionaturaValori.Stati
                .Where(stato => !string.Equals(stato, Campionatura.Stato, StringComparison.Ordinal))
                .ToArray()
            : CampionaturaValori.StatiDestinazioneOrdinaria(Campionatura.Stato);
        return true;
    }

    private void NormalizzaDatiWorkflow()
    {
        Esito = string.IsNullOrWhiteSpace(Esito) ? null : Esito.Trim();

        if (Stato == "Inviata al Cliente" && !DataConsegnaCampione.HasValue)
            ModelState.AddModelError(nameof(DataConsegnaCampione), "Indicare la data di consegna effettiva.");

        if (Stato == "Approvata" && Esito is not ("Positivo" or "Positivo con modifiche"))
            ModelState.AddModelError(nameof(Esito), "Selezionare un esito positivo.");
        else if (Stato == "Respinta" && Esito != "Negativo")
            ModelState.AddModelError(nameof(Esito), "Una campionatura respinta richiede esito Negativo.");
        else if (Stato == "In Lavorazione" && Esito is not null and not "Da rifare")
            ModelState.AddModelError(nameof(Esito), "Il ritorno in lavorazione ammette soltanto l'esito Da rifare.");
        else if (Stato is not ("Approvata" or "Respinta" or "In Lavorazione" or "Chiusa"))
            Esito = null;
    }

    internal static string MessaggioSql(int numero) => numero switch
    {
        52620 => "La campionatura non esiste.",
        52621 => "La campionatura e stata modificata da un altro utente. Ricaricare la pagina.",
        52622 => "La transizione di stato selezionata non e consentita.",
        52623 => "La correzione amministrativa richiede una motivazione.",
        52624 => "Indicare la data di consegna effettiva prima dell'invio al cliente.",
        52625 => "L'esito selezionato non e coerente con il nuovo stato.",
        52626 => "Sono presenti rilievi non ancora conclusi.",
        52627 => "Sono presenti adeguamenti ancora proposti o preparati.",
        _ => "Non e stato possibile aggiornare lo stato della campionatura."
    };
}

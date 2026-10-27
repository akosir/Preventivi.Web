using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public class ModificaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<ModificaModel> _logger;

    public ModificaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<ModificaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    [BindProperty]
    public CampionaturaFormModel Dati { get; set; } = new();

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public IReadOnlyList<CampionaturaRichiestaLookupItem> Richieste { get; private set; }
        = Array.Empty<CampionaturaRichiestaLookupItem>();
    public IReadOnlyList<CampionaturaPreventivoLookupItem> Preventivi { get; private set; }
        = Array.Empty<CampionaturaPreventivoLookupItem>();
    public IReadOnlyList<CampionaturaVarianteLookupItem> Varianti { get; private set; }
        = Array.Empty<CampionaturaVarianteLookupItem>();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        Dati = new CampionaturaFormModel
        {
            DataCampionatura = Campionatura!.DataCampionatura,
            IdRichiestaCliente = Campionatura.IdRichiestaCliente,
            IdPreventivo = Campionatura.IdPreventivo,
            IdVariantePreventivo = Campionatura.IdVariantePreventivo,
            Oggetto = Campionatura.Oggetto,
            DescrizioneCampione = Campionatura.DescrizioneCampione,
            Stato = Campionatura.Stato,
            Priorita = Campionatura.Priorita,
            DataRichiestaCampione = Campionatura.DataRichiestaCampione,
            DataPrevistaConsegna = Campionatura.DataPrevistaConsegna,
            DataConsegnaCampione = Campionatura.DataConsegnaCampione,
            DataChiusura = Campionatura.DataChiusura,
            Esito = Campionatura.Esito,
            Note = Campionatura.Note,
            VersioneRigaBase64 = Convert.ToBase64String(Campionatura.VersioneRiga)
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        ValidaCollegamenti();

        byte[] versioneRiga = [];
        try
        {
            versioneRiga = Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La campionatura e stata modificata. Ricaricare la pagina e riprovare.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _service.AggiornaAsync(
                CreaModello(id, versioneRiga, User.Identity?.Name ?? "Sistema"),
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Campionatura aggiornata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52600 and <= 52619)
        {
            _logger.LogWarning(exception, "Aggiornamento campionatura {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, MessaggioSql(exception.Number));
            return Page();
        }
    }

    private CampionaturaUpdateModel CreaModello(int id, byte[] versioneRiga, string utente) => new()
    {
        IdCampionatura = id,
        DataCampionatura = Dati.DataCampionatura.GetValueOrDefault(),
        IdRichiestaCliente = Dati.IdRichiestaCliente,
        IdPreventivo = Dati.IdPreventivo,
        IdVariantePreventivo = Dati.IdVariantePreventivo,
        Oggetto = Dati.Oggetto,
        DescrizioneCampione = Dati.DescrizioneCampione,
        Stato = Dati.Stato,
        Priorita = Dati.Priorita,
        DataRichiestaCampione = Dati.DataRichiestaCampione,
        DataPrevistaConsegna = Dati.DataPrevistaConsegna,
        DataConsegnaCampione = Dati.DataConsegnaCampione,
        DataChiusura = Dati.DataChiusura,
        Esito = Dati.Esito,
        Note = Dati.Note,
        Utente = utente,
        VersioneRiga = versioneRiga
    };

    private async Task<bool> CaricaContestoAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return false;
        }

        Campionatura = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Campionatura is null)
        {
            return false;
        }

        Richieste = await _repository.GetRichiesteAsync(cancellationToken);
        Preventivi = await _repository.GetPreventiviAsync(cancellationToken);
        Varianti = await _repository.GetVariantiAsync(cancellationToken);
        return true;
    }

    private void ValidaCollegamenti()
    {
        if (Richieste.All(elemento => elemento.IdRichiestaCliente != Dati.IdRichiestaCliente))
        {
            ModelState.AddModelError("Dati.IdRichiestaCliente", "Selezionare una richiesta cliente esistente.");
        }

        if (Dati.IdPreventivo.HasValue && Preventivi.All(elemento =>
                elemento.IdPreventivo != Dati.IdPreventivo ||
                elemento.IdRichiestaCliente != Dati.IdRichiestaCliente))
        {
            ModelState.AddModelError("Dati.IdPreventivo", "Il preventivo deve appartenere alla richiesta selezionata.");
        }

        if (Dati.IdVariantePreventivo.HasValue && Varianti.All(elemento =>
                elemento.IdVariantePreventivo != Dati.IdVariantePreventivo ||
                elemento.IdPreventivo != Dati.IdPreventivo))
        {
            ModelState.AddModelError("Dati.IdVariantePreventivo", "La variante deve appartenere al preventivo selezionato.");
        }
    }

    private static string MessaggioSql(int numero) => numero switch
    {
        52602 => "La richiesta cliente selezionata non esiste.",
        52603 => "Il preventivo deve appartenere alla richiesta selezionata.",
        52604 => "La variante deve appartenere al preventivo selezionato.",
        52606 => "La campionatura e stata modificata da un altro utente. Ricaricare la pagina.",
        52607 => "La data della campionatura deve rimanere nello stesso anno del numero progressivo.",
        _ => "I dati della campionatura non sono validi. Controllare i campi e riprovare."
    };
}

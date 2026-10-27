using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public class NuovaModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly ICampionaturaApplicationService _service;
    private readonly ILogger<NuovaModel> _logger;

    public NuovaModel(
        ICampionaturaRepository repository,
        ICampionaturaApplicationService service,
        ILogger<NuovaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    [BindProperty]
    public CampionaturaFormModel Dati { get; set; } = new();

    public IReadOnlyList<CampionaturaRichiestaLookupItem> Richieste { get; private set; }
        = Array.Empty<CampionaturaRichiestaLookupItem>();
    public IReadOnlyList<CampionaturaPreventivoLookupItem> Preventivi { get; private set; }
        = Array.Empty<CampionaturaPreventivoLookupItem>();
    public IReadOnlyList<CampionaturaVarianteLookupItem> Varianti { get; private set; }
        = Array.Empty<CampionaturaVarianteLookupItem>();

    public async Task OnGetAsync(int? idRichiestaCliente, CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);

        var richiesta = Richieste.FirstOrDefault(elemento =>
            elemento.IdRichiestaCliente == idRichiestaCliente);

        Dati = new CampionaturaFormModel
        {
            DataCampionatura = DateOnly.FromDateTime(DateTime.Today),
            DataRichiestaCampione = DateOnly.FromDateTime(DateTime.Today),
            IdRichiestaCliente = richiesta?.IdRichiestaCliente ?? 0,
            Oggetto = richiesta?.Oggetto ?? string.Empty,
            Priorita = richiesta?.Priorita ?? "Media",
            Stato = "Aperta"
        };
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);
        ValidaCollegamenti();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var id = await _service.CreaAsync(
                CreaModello(User.Identity?.Name ?? "Sistema"),
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Campionatura creata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52600 and <= 52619)
        {
            _logger.LogWarning(exception, "Creazione campionatura rifiutata");
            ModelState.AddModelError(string.Empty, MessaggioSql(exception.Number));
            return Page();
        }
    }

    private CampionaturaCreateModel CreaModello(string utente) => new()
    {
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
        Utente = utente
    };

    private async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        Richieste = await _repository.GetRichiesteAsync(cancellationToken);
        Preventivi = await _repository.GetPreventiviAsync(cancellationToken);
        Varianti = await _repository.GetVariantiAsync(cancellationToken);
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

    internal static string MessaggioSql(int numero) => numero switch
    {
        52602 => "La richiesta cliente selezionata non esiste.",
        52603 => "Il preventivo deve appartenere alla richiesta selezionata.",
        52604 => "La variante deve appartenere al preventivo selezionato.",
        52605 => "Non e stato possibile assegnare il numero progressivo. Riprovare.",
        _ => "I dati della campionatura non sono validi. Controllare i campi e riprovare."
    };
}

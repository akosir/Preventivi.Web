using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Core.RichiesteClienti;
using Preventivi.Web.UI.Modules.RichiesteClienti;

namespace Preventivi.Web.Pages.RichiesteClienti;

public class NuovaModel : PageModel
{
    private readonly IRichiestaClienteApplicationService _service;
    private readonly IClienteRepository _clienteRepository;
    private readonly ILogger<NuovaModel> _logger;

    public NuovaModel(
        IRichiestaClienteApplicationService service,
        IClienteRepository clienteRepository,
        ILogger<NuovaModel> logger)
    {
        _service = service;
        _clienteRepository = clienteRepository;
        _logger = logger;
    }

    [BindProperty]
    public RichiestaClienteFormModel Dati { get; set; } = new();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Dati = new RichiestaClienteFormModel
        {
            DataRichiesta = DateOnly.FromDateTime(DateTime.Today),
            Stato = "Nuova",
            Priorita = "Media"
        };

        await CaricaClientiAsync(cancellationToken);
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaClientiAsync(cancellationToken);

        if (Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente))
        {
            ModelState.AddModelError("Dati.IdCliente", "Selezionare un cliente attivo.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var id = await _service.CreaAsync(
                new RichiestaClienteCreateModel
                {
                    DataRichiesta = Dati.DataRichiesta,
                    IdCliente = Dati.IdCliente,
                    Oggetto = Dati.Oggetto,
                    DescrizioneRichiesta = Dati.DescrizioneRichiesta,
                    Stato = Dati.Stato,
                    Priorita = Dati.Priorita,
                    InteresseCliente = Dati.InteresseCliente,
                    DataScadenza = Dati.DataScadenza,
                    ProbabilitaChiusura = Dati.ProbabilitaChiusura,
                    Note = Dati.Note,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Richiesta cliente creata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52500 and <= 52519)
        {
            _logger.LogWarning(exception, "Creazione richiesta cliente rifiutata");
            ModelState.AddModelError(string.Empty, MessaggioSql(exception.Number));
            return Page();
        }
    }

    private async Task CaricaClientiAsync(CancellationToken cancellationToken)
    {
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: true,
            cancellationToken: cancellationToken);
    }

    private static string MessaggioSql(int numero) => numero switch
    {
        52502 => "Il cliente selezionato non e piu attivo.",
        52504 => "Non e stato possibile assegnare il numero progressivo. Riprovare.",
        _ => "I dati della richiesta non sono validi. Controllare i campi e riprovare."
    };
}

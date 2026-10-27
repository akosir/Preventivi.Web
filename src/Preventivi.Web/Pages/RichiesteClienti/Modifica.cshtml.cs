using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Core.RichiesteClienti;
using Preventivi.Web.UI.Modules.RichiesteClienti;

namespace Preventivi.Web.Pages.RichiesteClienti;

public class ModificaModel : PageModel
{
    private readonly IRichiestaClienteRepository _repository;
    private readonly IRichiestaClienteApplicationService _service;
    private readonly IClienteRepository _clienteRepository;
    private readonly ILogger<ModificaModel> _logger;

    public ModificaModel(
        IRichiestaClienteRepository repository,
        IRichiestaClienteApplicationService service,
        IClienteRepository clienteRepository,
        ILogger<ModificaModel> logger)
    {
        _repository = repository;
        _service = service;
        _clienteRepository = clienteRepository;
        _logger = logger;
    }

    [BindProperty]
    public RichiestaClienteFormModel Dati { get; set; } = new();

    public RichiestaClienteDettaglio? Richiesta { get; private set; }

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public bool ClienteBloccato =>
        Richiesta is not null &&
        (Richiesta.NumeroPreventivi > 0 || Richiesta.NumeroCampionature > 0);

    public bool StatoBloccato =>
        Richiesta is not null && RichiestaClienteValori.StatoFinale(Richiesta.Stato);

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        Dati = new RichiestaClienteFormModel
        {
            DataRichiesta = Richiesta!.DataRichiesta,
            IdCliente = Richiesta.IdCliente,
            Oggetto = Richiesta.Oggetto,
            DescrizioneRichiesta = Richiesta.DescrizioneRichiesta,
            Stato = Richiesta.Stato,
            Priorita = Richiesta.Priorita,
            InteresseCliente = Richiesta.InteresseCliente,
            DataScadenza = Richiesta.DataScadenza,
            ProbabilitaChiusura = Richiesta.ProbabilitaChiusura,
            Note = Richiesta.Note,
            VersioneRigaBase64 = Convert.ToBase64String(Richiesta.VersioneRiga)
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        if (ClienteBloccato && Dati.IdCliente != Richiesta!.IdCliente)
        {
            ModelState.AddModelError("Dati.IdCliente", "Il cliente non puo essere modificato perche esistono documenti collegati.");
        }
        else if (Dati.IdCliente != Richiesta!.IdCliente &&
                 Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente || !cliente.Attivo))
        {
            ModelState.AddModelError("Dati.IdCliente", "Selezionare un cliente attivo.");
        }

        if (StatoBloccato && !string.Equals(Dati.Stato, Richiesta.Stato, StringComparison.Ordinal))
        {
            ModelState.AddModelError("Dati.Stato", "Lo stato finale non puo essere riaperto.");
        }

        byte[] versioneRiga = [];
        try
        {
            versioneRiga = Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La richiesta e stata modificata. Ricaricare la pagina e riprovare.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _service.AggiornaAsync(
                new RichiestaClienteUpdateModel
                {
                    IdRichiestaCliente = id,
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
                    Utente = User.Identity?.Name ?? "Sistema",
                    VersioneRiga = versioneRiga
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Richiesta cliente aggiornata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52500 and <= 52519)
        {
            _logger.LogWarning(exception, "Aggiornamento richiesta cliente {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, MessaggioSql(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaContestoAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return false;
        }

        Richiesta = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Richiesta is null)
        {
            return false;
        }

        var clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);

        Clienti = clienti
            .Where(cliente => cliente.Attivo || cliente.IdCliente == Richiesta.IdCliente)
            .ToArray();

        return true;
    }

    private static string MessaggioSql(int numero) => numero switch
    {
        52502 => "Il cliente selezionato non e attivo.",
        52506 => "La richiesta e stata modificata da un altro utente. Ricaricare la pagina.",
        52507 => "Il cliente non puo essere modificato perche esistono documenti collegati.",
        52508 => "Uno stato finale non puo essere riaperto.",
        52510 => "La data della richiesta deve rimanere nello stesso anno del numero progressivo.",
        _ => "I dati della richiesta non sono validi. Controllare i campi e riprovare."
    };
}

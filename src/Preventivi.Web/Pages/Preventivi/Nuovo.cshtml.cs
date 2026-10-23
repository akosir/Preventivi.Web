using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class NuovoModel : PageModel
{
    public const string OrigineLibero = "Libero";
    public const string OrigineRichiesta = "Richiesta";
    public const string OrigineModello = "Modello";

    private static readonly string[] OriginiDisponibili =
    [
        OrigineLibero,
        OrigineRichiesta,
        OrigineModello
    ];

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IClienteRepository _clienteRepository;
    private readonly ILogger<NuovoModel> _logger;

    public NuovoModel(
        IPreventivoRepository preventivoRepository,
        IClienteRepository clienteRepository,
        ILogger<NuovoModel> logger)
    {
        _preventivoRepository = preventivoRepository;
        _clienteRepository = clienteRepository;
        _logger = logger;
    }

    [BindProperty]
    public PreventivoCreateModel Dati { get; set; } = new();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public IReadOnlyList<PreventivoRichiestaLookupItem> Richieste { get; private set; }
        = Array.Empty<PreventivoRichiestaLookupItem>();

    public IReadOnlyList<PreventivoModelloLookupItem> Modelli { get; private set; }
        = Array.Empty<PreventivoModelloLookupItem>();

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        Dati = new PreventivoCreateModel
        {
            Origine = OrigineLibero,
            DataPreventivo = DateOnly.FromDateTime(DateTime.Today),
            MarkupPercDefault = 60
        };

        await CaricaLookupAsync(cancellationToken);
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);
        ValidaDati();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var idPreventivo = await _preventivoRepository.CreaPreventivoAsync(
                Dati,
                cancellationToken);

            return RedirectToPage("/Preventivi/Dettaglio", new { id = idPreventivo });
        }
        catch (SqlException exception) when (IsErroreCreazionePrevisto(exception.Number))
        {
            _logger.LogWarning(
                exception,
                "Creazione preventivo rifiutata per dati o contesto non validi");

            ModelState.AddModelError(string.Empty, GetMessaggioCreazione(exception.Number));
            return Page();
        }
    }

    private async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: true,
            cancellationToken: cancellationToken);
        Richieste = await _preventivoRepository.GetRichiesteCreazioneAsync(cancellationToken);
        Modelli = await _preventivoRepository.GetModelliPreventivoAsync(cancellationToken);

        var idClientiAttivi = Clienti
            .Select(cliente => cliente.IdCliente)
            .ToHashSet();

        foreach (var richiesta in Richieste)
        {
            richiesta.ClienteAttivo =
                richiesta.IdCliente.HasValue &&
                idClientiAttivi.Contains(richiesta.IdCliente.Value);
        }
    }

    private void ValidaDati()
    {
        Dati.Origine = Dati.Origine?.Trim() ?? string.Empty;
        Dati.Oggetto = Dati.Oggetto?.Trim() ?? string.Empty;
        Dati.Note = string.IsNullOrWhiteSpace(Dati.Note) ? null : Dati.Note.Trim();

        if (!OriginiDisponibili.Contains(Dati.Origine, StringComparer.OrdinalIgnoreCase))
        {
            ModelState.AddModelError("Dati.Origine", "Selezionare un'origine valida.");
        }

        if (Dati.DataPreventivo == default)
        {
            ModelState.AddModelError("Dati.DataPreventivo", "Inserire la data del preventivo.");
        }

        if (string.IsNullOrWhiteSpace(Dati.Oggetto))
        {
            ModelState.AddModelError("Dati.Oggetto", "Inserire l'oggetto del preventivo.");
        }

        if (Dati.MarkupPercDefault < 0)
        {
            ModelState.AddModelError("Dati.MarkupPercDefault", "Il markup non puo essere negativo.");
        }

        if (string.Equals(Dati.Origine, OrigineRichiesta, StringComparison.OrdinalIgnoreCase))
        {
            var richiesta = Dati.IdRichiestaCliente.HasValue
                ? Richieste.FirstOrDefault(
                    elemento => elemento.IdRichiestaCliente == Dati.IdRichiestaCliente.Value)
                : null;

            if (richiesta is null)
            {
                ModelState.AddModelError("Dati.IdRichiestaCliente", "Selezionare una richiesta cliente valida.");
            }
            else
            {
                Dati.IdCliente = richiesta.IdCliente;

                if (!richiesta.IdCliente.HasValue)
                {
                    ModelState.AddModelError(
                        "Dati.IdCliente",
                        "La richiesta non ha un cliente associato.");
                }
                else if (!richiesta.ClienteAttivo)
                {
                    ModelState.AddModelError(
                        "Dati.IdCliente",
                        "Il cliente collegato alla richiesta non e attivo. Riattivarlo prima di creare il preventivo.");
                }
            }
        }
        else
        {
            Dati.IdRichiestaCliente = null;

            if (Dati.IdCliente.HasValue &&
                Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente.Value))
            {
                ModelState.AddModelError("Dati.IdCliente", "Il cliente selezionato non e disponibile.");
            }

            if (string.Equals(Dati.Origine, OrigineLibero, StringComparison.OrdinalIgnoreCase) &&
                !Dati.IdCliente.HasValue)
            {
                ModelState.AddModelError("Dati.IdCliente", "Selezionare il cliente.");
            }
        }

        if (string.Equals(Dati.Origine, OrigineModello, StringComparison.OrdinalIgnoreCase))
        {
            if (!Dati.IdModelloPreventivo.HasValue ||
                Modelli.All(modello => modello.IdModelloPreventivo != Dati.IdModelloPreventivo.Value))
            {
                ModelState.AddModelError("Dati.IdModelloPreventivo", "Selezionare un modello preventivo valido.");
            }
        }
        else
        {
            Dati.IdModelloPreventivo = null;
        }
    }

    private static bool IsErroreCreazionePrevisto(int numero) =>
        numero is >= 51801 and <= 51810 or 2601 or 2627;

    private static string GetMessaggioCreazione(int numero) => numero switch
    {
        51804 => "La richiesta cliente selezionata non e piu disponibile.",
        51805 => "Il modello preventivo selezionato non e piu disponibile.",
        51806 => "Il cliente selezionato non e disponibile.",
        51808 => "Non e stato possibile assegnare il numero progressivo. Riprovare.",
        51809 => "Il modello contiene una o piu righe con tipo non valido o non attivo.",
        51810 => "Il cliente collegato alla richiesta non e attivo. Riattivarlo prima di creare il preventivo.",
        2601 or 2627 => "Il numero del preventivo e stato utilizzato da un'altra operazione. Riprovare.",
        _ => "I dati del preventivo non sono validi. Controllare i campi e riprovare."
    };
}

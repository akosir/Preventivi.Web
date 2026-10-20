using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class ModificaModel : PageModel
{
    private static readonly string[] StatiDisponibili =
    [
        "Bozza",
        "Da Verificare",
        "Pronto da Inviare",
        "Inviato",
        "Accettato",
        "Respinto",
        "In Produzione",
        "Chiuso",
        "Annullato"
    ];

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IClienteRepository _clienteRepository;

    public ModificaModel(
        IPreventivoRepository preventivoRepository,
        IClienteRepository clienteRepository)
    {
        _preventivoRepository = preventivoRepository;
        _clienteRepository = clienteRepository;
    }

    public PreventivoDettaglio? Preventivo { get; private set; }

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public IReadOnlyList<string> Stati => StatiDisponibili;

    [BindProperty]
    public PreventivoUpdateModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        Dati = new PreventivoUpdateModel
        {
            IdPreventivo = Preventivo!.IdPreventivo,
            DataPreventivo = Preventivo.DataPreventivo,
            IdCliente = Preventivo.IdCliente,
            Oggetto = Preventivo.Oggetto,
            Note = Preventivo.Note,
            Stato = Preventivo.Stato,
            MarkupPercDefault = Preventivo.MarkupPercDefault,
            IdRichiestaCliente = Preventivo.IdRichiestaCliente
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(id, cancellationToken))
        {
            return NotFound();
        }

        Dati.IdPreventivo = id;

        if (string.IsNullOrWhiteSpace(Dati.Oggetto))
        {
            ModelState.AddModelError("Dati.Oggetto", "Inserire l'oggetto del preventivo.");
        }

        if (!StatiDisponibili.Contains(Dati.Stato, StringComparer.OrdinalIgnoreCase))
        {
            ModelState.AddModelError("Dati.Stato", "Selezionare uno stato valido.");
        }

        if (Dati.MarkupPercDefault < 0)
        {
            ModelState.AddModelError("Dati.MarkupPercDefault", "Il markup non puo essere negativo.");
        }

        if (Dati.IdCliente is > 0 && Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente))
        {
            ModelState.AddModelError("Dati.IdCliente", "Il cliente selezionato non e disponibile.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        await _preventivoRepository.AggiornaPreventivoAsync(Dati, cancellationToken);

        return RedirectToPage("/Preventivi/Dettaglio", new { id });
    }

    private async Task<bool> CaricaContestoAsync(
        int id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return false;
        }

        Preventivo = await _preventivoRepository.GetDettaglioAsync(id, cancellationToken);
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);

        return Preventivo is not null;
    }
}

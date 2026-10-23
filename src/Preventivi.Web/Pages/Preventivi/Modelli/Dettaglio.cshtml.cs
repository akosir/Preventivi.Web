using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli;

public sealed class DettaglioModel : PageModel
{
    private readonly IModelloPreventivoRepository _repository;
    private readonly IClienteRepository _clienteRepository;

    public DettaglioModel(
        IModelloPreventivoRepository repository,
        IClienteRepository clienteRepository)
    {
        _repository = repository;
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int Id { get; set; }

    [BindProperty]
    public ModelloPreventivoFormModel Dati { get; set; } = new();

    public ModelloPreventivoDettaglio? Modello { get; private set; }

    public IReadOnlyList<ModelloPreventivoRigaItem> Righe { get; private set; }
        = Array.Empty<ModelloPreventivoRigaItem>();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public ModelloPreventivoFormViewModel Form => new(Dati, Clienti);

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(cancellationToken))
            return NotFound();

        Dati = new ModelloPreventivoFormModel
        {
            CodiceModelloPreventivo = Modello!.CodiceModelloPreventivo,
            Descrizione = Modello.Descrizione,
            IdCliente = Modello.IdCliente,
            Oggetto = Modello.Oggetto,
            Note = Modello.Note
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(cancellationToken))
            return NotFound();

        if (Dati.IdCliente.HasValue &&
            Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente.Value))
        {
            ModelState.AddModelError("Dati.IdCliente", "Il cliente selezionato non esiste.");
        }

        if (!ModelState.IsValid)
            return Page();

        try
        {
            await _repository.AggiornaAsync(
                new ModelloPreventivoUpdateModel
                {
                    IdModelloPreventivo = Id,
                    CodiceModelloPreventivo = Dati.CodiceModelloPreventivo,
                    Descrizione = Dati.Descrizione,
                    IdCliente = Dati.IdCliente,
                    Oggetto = Dati.Oggetto,
                    Note = Dati.Note
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Modello preventivo aggiornato correttamente.";
            return RedirectToPage(new { id = Id });
        }
        catch (SqlException exception) when (exception.Number is 2601 or 2627)
        {
            ModelState.AddModelError(
                "Dati.CodiceModelloPreventivo",
                "Il codice modello e gia utilizzato.");
            return Page();
        }
        catch (SqlException exception) when (exception.Number is >= 52110 and <= 52113)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
    }

    private async Task<bool> CaricaContestoAsync(CancellationToken cancellationToken)
    {
        Modello = await _repository.GetDettaglioAsync(Id, cancellationToken);
        if (Modello is null)
            return false;

        Righe = await _repository.GetRigheAsync(Id, cancellationToken);
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);
        return true;
    }
}

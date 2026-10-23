using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli;

public sealed class NuovoModel : PageModel
{
    private readonly IModelloPreventivoRepository _repository;
    private readonly IClienteRepository _clienteRepository;

    public NuovoModel(
        IModelloPreventivoRepository repository,
        IClienteRepository clienteRepository)
    {
        _repository = repository;
        _clienteRepository = clienteRepository;
    }

    [BindProperty]
    public ModelloPreventivoFormModel Dati { get; set; } = new();

    public IReadOnlyList<ClienteListItem> Clienti { get; private set; }
        = Array.Empty<ClienteListItem>();

    public ModelloPreventivoFormViewModel Form => new(Dati, Clienti);

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        await CaricaClientiAsync(cancellationToken);
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaClientiAsync(cancellationToken);
        ValidaCliente();

        if (!ModelState.IsValid)
            return Page();

        try
        {
            var id = await _repository.CreaAsync(
                new ModelloPreventivoCreateModel
                {
                    CodiceModelloPreventivo = Dati.CodiceModelloPreventivo,
                    Descrizione = Dati.Descrizione,
                    IdCliente = Dati.IdCliente,
                    Oggetto = Dati.Oggetto,
                    Note = Dati.Note
                },
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Modello preventivo creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
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

    private async Task CaricaClientiAsync(CancellationToken cancellationToken)
    {
        Clienti = await _clienteRepository.GetElencoAsync(
            soloAttivi: null,
            cancellationToken: cancellationToken);
    }

    private void ValidaCliente()
    {
        if (Dati.IdCliente.HasValue &&
            Clienti.All(cliente => cliente.IdCliente != Dati.IdCliente.Value))
        {
            ModelState.AddModelError("Dati.IdCliente", "Il cliente selezionato non esiste.");
        }
    }
}

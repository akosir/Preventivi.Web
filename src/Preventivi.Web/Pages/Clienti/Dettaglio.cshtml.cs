using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Web.UI.Modules.Clienti;

namespace Preventivi.Web.Pages.Clienti;

public class DettaglioModel : PageModel
{
    private readonly IClienteRepository _clienteRepository;

    public DettaglioModel(
        IClienteRepository clienteRepository)
    {
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdCliente { get; set; }

    [BindProperty]
    public ClienteFormModel Cliente { get; set; } = new();

    public ClientiHeaderModel Header { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(
        CancellationToken cancellationToken)
    {
        Header = CreaHeader();

        var cliente =
            await _clienteRepository.GetByIdAsync(
                IdCliente,
                cancellationToken);

        if (cliente is null)
        {
            return NotFound();
        }

        Cliente = new ClienteFormModel
        {
            CodiceCliente = cliente.CodiceCliente,
            RagioneSociale = cliente.RagioneSociale,
            PartitaIVA = cliente.PartitaIVA,
            CodiceFiscale = cliente.CodiceFiscale,
            Indirizzo = cliente.Indirizzo,
            CAP = cliente.CAP,
            Citta = cliente.Citta,
            Provincia = cliente.Provincia,
            Telefono = cliente.Telefono,
            Email = cliente.Email,
            Attivo = cliente.Attivo
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        CancellationToken cancellationToken)
    {
        Header = CreaHeader();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var modello = new ClienteUpdateModel
        {
            IdCliente = IdCliente,
            CodiceCliente = Cliente.CodiceCliente.Trim(),
            RagioneSociale = Cliente.RagioneSociale.Trim(),
            PartitaIVA = Pulisci(Cliente.PartitaIVA),
            CodiceFiscale = Pulisci(Cliente.CodiceFiscale),
            Indirizzo = Pulisci(Cliente.Indirizzo),
            CAP = Pulisci(Cliente.CAP),
            Citta = Pulisci(Cliente.Citta),
            Provincia = Pulisci(Cliente.Provincia),
            Telefono = Pulisci(Cliente.Telefono),
            Email = Pulisci(Cliente.Email),
            Attivo = Cliente.Attivo
        };

        try
        {
            await _clienteRepository.AggiornaAsync(
                modello,
                cancellationToken);

            TempData["MessaggioSuccesso"] =
                "Cliente aggiornato correttamente.";

            return RedirectToPage("./Index");
        }
        catch (SqlException ex)
        {
            if (ex.Message.Contains("UQ_Clienti_CodiceCliente"))
            {
                ModelState.AddModelError(
                    nameof(Cliente.CodiceCliente),
                    "Il codice cliente è già presente.");

                return Page();
            }

            throw;
        }
    }

    private static ClientiHeaderModel CreaHeader()
    {
        return new ClientiHeaderModel
        {
            Titolo = "Dettaglio Cliente",
            Sottotitolo = "Modifica anagrafica cliente",
            TestoPulsanteNuovo = "",
            UrlNuovo = "#"
        };
    }

    private static string? Pulisci(string? valore)
    {
        return string.IsNullOrWhiteSpace(valore)
            ? null
            : valore.Trim();
    }
}
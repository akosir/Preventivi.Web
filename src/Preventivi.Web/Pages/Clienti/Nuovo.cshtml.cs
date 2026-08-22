using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Web.UI.Modules.Clienti;
using Microsoft.Data.SqlClient;

namespace Preventivi.Web.Pages.Clienti;

public class NuovoModel : PageModel
{
    private readonly IClienteRepository _clienteRepository;

    public NuovoModel(
        IClienteRepository clienteRepository)
    {
        _clienteRepository = clienteRepository;
    }

    public ClientiHeaderModel Header { get; private set; } = new();

    [BindProperty]
    public ClienteFormModel Cliente { get; set; } = new();

    public void OnGet()
    {
        Header = CreaHeader();
    }

    public async Task<IActionResult> OnPostAsync(
        CancellationToken cancellationToken)
    {
        Header = CreaHeader();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var modello = new ClienteCreateModel
        {
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
            var idCliente =
                await _clienteRepository.CreaAsync(
                    modello,
                    cancellationToken);

            TempData["MessaggioSuccesso"] =
                "Cliente creato correttamente.";

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
            Titolo = "Nuovo Cliente",
            Sottotitolo = "Inserimento nuova anagrafica cliente",
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
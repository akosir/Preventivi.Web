using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Web.UI.Modules.Clienti;

namespace Preventivi.Web.Pages.Clienti;

public class DisattivaModel : PageModel
{
    private readonly IClienteRepository _clienteRepository;

    public DisattivaModel(
        IClienteRepository clienteRepository)
    {
        _clienteRepository = clienteRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdCliente { get; set; }

    [BindProperty]
    public string RagioneSociale { get; set; } = "";

    public ClientiHeaderModel Header { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(
        CancellationToken cancellationToken)
    {
        Header = new ClientiHeaderModel
        {
            Titolo = "Disattiva Cliente",
            Sottotitolo = "Conferma operazione"
        };

        var cliente =
            await _clienteRepository.GetByIdAsync(
                IdCliente,
                cancellationToken);

        if (cliente is null)
        {
            return NotFound();
        }

        RagioneSociale = cliente.RagioneSociale;

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        CancellationToken cancellationToken)
    {
        await _clienteRepository.DisattivaAsync(
            IdCliente,
            cancellationToken);

        TempData["MessaggioSuccesso"] =
            "Cliente disattivato correttamente.";

        return RedirectToPage("./Index");
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class EliminaModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public EliminaModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdPreventivo { get; set; }

    [BindProperty(SupportsGet = true)]
    public int IdRigaPreventivo { get; set; }

    public PreventivoRigaDettaglio? Riga { get; private set; }

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        Riga =
            await _preventivoRepository.GetRigaAsync(
                IdRigaPreventivo,
                cancellationToken);

        if (Riga is null)
        {
            return NotFound();
        }

        IdPreventivo = Riga.IdPreventivo;

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await _preventivoRepository.EliminaRigaAsync(
            IdRigaPreventivo,
            cancellationToken);

        return RedirectToPage(
            "/Preventivi/Dettaglio",
            new
            {
                id = IdPreventivo
            });
    }
}

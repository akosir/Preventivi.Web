using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Varianti;

public class DettaglioModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public DettaglioModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdPreventivo { get; set; }

    [BindProperty(SupportsGet = true)]
    public int IdVariantePreventivo { get; set; }

    public PreventivoVarianteItem? Variante { get; private set; }

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        Variante =
            await _preventivoRepository.GetVarianteAsync(
                IdVariantePreventivo,
                cancellationToken);

        if (Variante is null)
        {
            return NotFound();
        }

        IdPreventivo = Variante.IdPreventivo;

        return Page();
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Varianti;

public class NuovoModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public NuovoModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdPreventivo { get; set; }

    [BindProperty]
    public PreventivoVarianteCreateModel Variante { get; set; } = new();

    public IActionResult OnGet()
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        Variante.IdPreventivo = IdPreventivo;

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        Variante.IdPreventivo = IdPreventivo;

        if (string.IsNullOrWhiteSpace(Variante.CodiceVariante))
        {
            ModelState.AddModelError(
                "Variante.CodiceVariante",
                "Inserire il codice variante.");
        }

        if (string.IsNullOrWhiteSpace(Variante.DescrizioneVariante))
        {
            ModelState.AddModelError(
                "Variante.DescrizioneVariante",
                "Inserire la descrizione variante.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        await _preventivoRepository.CreaVarianteAsync(
            Variante,
            cancellationToken);

        return RedirectToPage(
            "/Preventivi/Dettaglio",
            new { id = IdPreventivo });
    }
}

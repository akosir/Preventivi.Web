using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Varianti;

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

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        Variante = await _preventivoRepository.GetVarianteAsync(
            IdVariantePreventivo,
            cancellationToken);

        if (Variante is null || Variante.IdPreventivo != IdPreventivo)
        {
            return NotFound();
        }

        try
        {
            await _preventivoRepository.EliminaVarianteAsync(
                IdVariantePreventivo,
                cancellationToken);
        }
        catch (SqlException exception) when (exception.Number == 1934)
        {
            ModelState.AddModelError(
                string.Empty,
                "La configurazione database delle varianti non è aggiornata. Applicare lo script di correzione TEC-009.");
            return Page();
        }

        return RedirectToPage(
            "/Preventivi/Dettaglio",
            new { id = IdPreventivo });
    }
}

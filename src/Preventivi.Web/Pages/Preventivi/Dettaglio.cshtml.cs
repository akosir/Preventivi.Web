using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class DettaglioModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public PreventivoDettaglio? Preventivo { get; private set; }

    public DettaglioModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public async Task<IActionResult> OnGetAsync(
        int id,
        CancellationToken cancellationToken)
    {
        Preventivo =
            await _repository.GetDettaglioAsync(id, cancellationToken);

        if (Preventivo is null)
            return NotFound();

        return Page();
    }
}
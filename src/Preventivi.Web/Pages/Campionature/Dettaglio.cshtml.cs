using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Campionature;

namespace Preventivi.Web.Pages.Campionature;

public class DettaglioModel : PageModel
{
    private readonly ICampionaturaRepository _repository;

    public DettaglioModel(ICampionaturaRepository repository)
    {
        _repository = repository;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return NotFound();
        }

        Campionatura = await _repository.GetDettaglioAsync(id, cancellationToken);
        return Campionatura is null ? NotFound() : Page();
    }
}

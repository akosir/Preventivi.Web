using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class WorkspaceModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public PreventivoDettaglio? Preventivo { get; private set; }

    public PreventivoRigaListItem? Riga { get; private set; }

    public WorkspaceModel(
        IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo,
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        if (idPreventivo <= 0 ||
            idRigaPreventivo <= 0)
        {
            return BadRequest();
        }

        Preventivo =
            await _preventivoRepository.GetDettaglioAsync(
                idPreventivo,
                cancellationToken);

        if (Preventivo is null)
        {
            return NotFound();
        }

        var righe =
            await _preventivoRepository.GetRigheAsync(
                idPreventivo,
                cancellationToken);

        Riga =
            righe.FirstOrDefault(
                r => r.IdRigaPreventivo == idRigaPreventivo);

        if (Riga is null)
        {
            return NotFound();
        }

        return Page();
    }
}

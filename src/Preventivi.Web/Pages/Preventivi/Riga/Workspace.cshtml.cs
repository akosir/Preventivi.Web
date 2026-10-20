using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class WorkspaceModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public PreventivoDettaglio? Preventivo { get; private set; }

    public PreventivoRigaDettaglio? Riga { get; private set; }

    public IReadOnlyList<PreventivoRigaComponenteItem> Componenti { get; private set; }
        = Array.Empty<PreventivoRigaComponenteItem>();

    public bool RigaLibera { get; private set; }

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

        Riga =
            await _preventivoRepository.GetRigaAsync(
                idRigaPreventivo,
                cancellationToken);

        if (Riga is null ||
            Riga.IdPreventivo != idPreventivo)
        {
            return NotFound();
        }

        var tipiRiga = await _preventivoRepository.GetTipiRigaAsync(cancellationToken);
        RigaLibera = tipiRiga.Any(tipo =>
            tipo.IdTipoRiga == Riga.IdTipoRiga && tipo.RigaLibera);

        Componenti =
            await _preventivoRepository.GetComponentiAsync(
                idRigaPreventivo,
                cancellationToken);

        return Page();
    }
}

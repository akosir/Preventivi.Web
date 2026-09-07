using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Preventivi;

public class DettaglioModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IAllegatoRepository _allegatoRepository;

    public PreventivoDettaglio? Preventivo { get; private set; }

    public IReadOnlyList<PreventivoRigaListItem> Righe { get; private set; }
        = Array.Empty<PreventivoRigaListItem>();

    public IReadOnlyList<PreventivoVarianteItem> Varianti { get; private set; }
        = Array.Empty<PreventivoVarianteItem>();

    public AllegatiGridModel Allegati { get; private set; } = new();

    public DettaglioModel(
        IPreventivoRepository preventivoRepository,
        IAllegatoRepository allegatoRepository)
    {
        _preventivoRepository = preventivoRepository;
        _allegatoRepository = allegatoRepository;
    }

    public async Task<IActionResult> OnGetAsync(
        int id,
        CancellationToken cancellationToken)
    {
        Preventivo =
            await _preventivoRepository.GetDettaglioAsync(
                id,
                cancellationToken);

        if (Preventivo is null)
        {
            return NotFound();
        }

        Righe =
            await _preventivoRepository.GetRigheAsync(
                id,
                cancellationToken);

        Varianti =
            await _preventivoRepository.GetVariantiAsync(
                id,
                cancellationToken);

        Allegati = new AllegatiGridModel
        {
            Allegati =
                await _allegatoRepository.GetElencoAsync(
                    "Preventivi",
                    id,
                    cancellationToken)
        };

        return Page();
    }
}

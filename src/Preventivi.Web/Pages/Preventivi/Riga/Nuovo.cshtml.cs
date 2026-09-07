using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

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
    public PreventivoRigaCreateModel Riga { get; set; } = new();

    public IReadOnlyList<TipoRigaPreventivoItem> TipiRiga { get; private set; }
        = Array.Empty<TipoRigaPreventivoItem>();

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        await CaricaTipiAsync(cancellationToken);

        Riga = new PreventivoRigaCreateModel
        {
            IdPreventivo = IdPreventivo,
            Quantita = 1,
            MarkupPerc = 0,
            IdTipoRiga = TipiRiga.FirstOrDefault()?.IdTipoRiga ?? 0
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        Riga.IdPreventivo = IdPreventivo;

        if (string.IsNullOrWhiteSpace(Riga.DescrizioneVoce))
        {
            ModelState.AddModelError(
                "Riga.DescrizioneVoce",
                "Inserire la descrizione della riga.");
        }

        if (Riga.IdTipoRiga <= 0)
        {
            ModelState.AddModelError(
                "Riga.IdTipoRiga",
                "Selezionare il tipo riga.");
        }

        if (Riga.Quantita <= 0)
        {
            ModelState.AddModelError(
                "Riga.Quantita",
                "La quantità deve essere maggiore di zero.");
        }

        if (!ModelState.IsValid)
        {
            await CaricaTipiAsync(cancellationToken);
            return Page();
        }

        var idRigaPreventivo =
            await _preventivoRepository.CreaRigaAsync(
                Riga,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Workspace",
            new
            {
                idPreventivo = IdPreventivo,
                idRigaPreventivo
            });
    }

    private async Task CaricaTipiAsync(CancellationToken cancellationToken)
    {
        TipiRiga =
            await _preventivoRepository.GetTipiRigaAsync(cancellationToken);
    }
}

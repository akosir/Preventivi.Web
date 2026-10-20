using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;
using Preventivi.Core.Preventivi.Eliminazione;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class EliminaModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IPreventivoEliminazioneService _eliminazioneService;

    public EliminaModel(
        IPreventivoRepository preventivoRepository,
        IPreventivoEliminazioneService eliminazioneService)
    {
        _preventivoRepository = preventivoRepository;
        _eliminazioneService = eliminazioneService;
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
        Riga = await _preventivoRepository.GetRigaAsync(
            IdRigaPreventivo,
            cancellationToken);

        if (Riga is null || Riga.IdPreventivo != IdPreventivo)
        {
            return NotFound();
        }

        try
        {
            await _eliminazioneService.EliminaAsync(
                TipoEliminazionePreventivo.Riga,
                IdRigaPreventivo,
                cancellationToken);
        }
        catch (PreventivoEliminazioneException exception)
        {
            if (exception.EliminazioneCompletata)
            {
                return RedirectToPage("/Preventivi/Dettaglio", new { id = IdPreventivo });
            }

            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }

        return RedirectToPage(
            "/Preventivi/Dettaglio",
            new
            {
                id = IdPreventivo
            });
    }
}

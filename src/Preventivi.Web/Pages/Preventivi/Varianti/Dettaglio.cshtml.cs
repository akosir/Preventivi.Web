using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
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
    public PreventivoDettaglio? Preventivo { get; private set; }
    public IReadOnlyList<PreventivoRigaListItem> Righe { get; private set; } = [];
    public bool Modificabile => Variante?.Attiva == true && PreventivoMarkupAnteprima.StatoModificabile(Preventivo?.Stato ?? "");

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        Variante =
            await _preventivoRepository.GetVarianteAsync(
                IdVariantePreventivo,
                cancellationToken);

        if (Variante is null || (IdPreventivo > 0 && Variante.IdPreventivo != IdPreventivo))
        {
            return NotFound();
        }

        IdPreventivo = Variante.IdPreventivo;
        Preventivo = await _preventivoRepository.GetDettaglioAsync(IdPreventivo, cancellationToken);
        if (Preventivo is null) return NotFound();
        Righe = await _preventivoRepository.GetRigheVarianteAsync(IdPreventivo, IdVariantePreventivo, cancellationToken);

        return Page();
    }

    public async Task<IActionResult> OnPostSelezionaAsync(
        CancellationToken cancellationToken)
    {
        var pagina = await OnGetAsync(cancellationToken);
        if (pagina is not PageResult) return pagina;
        if (!Modificabile)
        {
            ModelState.AddModelError(string.Empty, "Lo stato del preventivo o della variante non consente la selezione.");
            return Page();
        }
        try
        {
            await _preventivoRepository.SelezionaVarianteAsync(IdVariantePreventivo, cancellationToken);
        }
        catch (SqlException exception) when (exception.Number is >= 51951 and <= 51959 or 547)
        {
            ModelState.AddModelError(string.Empty, "La selezione della variante è bloccata dai dati correnti. Riaprire il preventivo e verificare la variante.");
            return Page();
        }

        return RedirectToPage(
            "/Preventivi/Dettaglio",
            new { id = IdPreventivo });
    }
}

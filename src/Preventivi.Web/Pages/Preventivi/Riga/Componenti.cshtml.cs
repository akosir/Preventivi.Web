using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class ComponentiModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    [BindProperty]
    public PreventivoRigaComponenteCreateModel NuovoComponente { get; set; } = new();

    public ComponentiModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    public async Task<IActionResult> OnGetAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, id))
        {
            return BadRequest();
        }

        if (IsNuovo(modo))
        {
            NuovoComponente = new PreventivoRigaComponenteCreateModel
            {
                IdRigaPreventivo = idRigaPreventivo,
                Livello = 0,
                QuantitaBase = 1,
                QuantitaCalcolata = 1,
                OrdineVisualizzazione = 10
            };

            return Page();
        }

        Componente =
            await _preventivoRepository.GetComponenteAsync(
                id!.Value,
                cancellationToken);

        if (Componente is null ||
            Componente.IdRigaPreventivo != idRigaPreventivo)
        {
            return NotFound();
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, id))
        {
            return BadRequest();
        }

        if (IsElimina(modo))
        {
            await _preventivoRepository.EliminaComponenteAsync(
                id!.Value,
                cancellationToken);

            return RedirectToWorkspace(idPreventivo, idRigaPreventivo);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        if (string.IsNullOrWhiteSpace(NuovoComponente.DescrizioneNodo))
        {
            ModelState.AddModelError(
                nameof(NuovoComponente.DescrizioneNodo),
                "La descrizione del componente e obbligatoria.");
        }

        NuovoComponente.IdRigaPreventivo = idRigaPreventivo;

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idComponente =
            await _preventivoRepository.CreaComponenteAsync(
                NuovoComponente,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Componenti",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                id = idComponente
            });
    }

    public IActionResult RedirectToWorkspace(
        int idPreventivo,
        int idRigaPreventivo)
    {
        return RedirectToPage(
            "/Preventivi/Riga/Workspace",
            new
            {
                idPreventivo,
                idRigaPreventivo
            });
    }

    public static bool IsNuovo(string modo) =>
        string.Equals(modo, "nuovo", StringComparison.OrdinalIgnoreCase);

    public static bool IsElimina(string modo) =>
        string.Equals(modo, "elimina", StringComparison.OrdinalIgnoreCase);

    public static bool IsDettaglio(string modo) =>
        string.Equals(modo, "dettaglio", StringComparison.OrdinalIgnoreCase);

    private static bool IsRequestValid(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int? id)
    {
        if (idPreventivo <= 0 ||
            idRigaPreventivo <= 0)
        {
            return false;
        }

        if (IsNuovo(modo))
        {
            return true;
        }

        return (IsDettaglio(modo) || IsElimina(modo)) &&
            id is > 0;
    }
}

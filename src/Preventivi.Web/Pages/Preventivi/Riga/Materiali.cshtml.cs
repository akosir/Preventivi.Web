using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class MaterialiModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public PreventivoRigaMaterialeItem? Materiale { get; private set; }

    [BindProperty]
    public PreventivoRigaMaterialeCreateModel NuovoMateriale { get; set; } = new();

    public MaterialiModel(IPreventivoRepository preventivoRepository)
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
            NuovoMateriale = new PreventivoRigaMaterialeCreateModel
            {
                IdRigaPreventivo = idRigaPreventivo,
                Quantita = 1
            };

            return Page();
        }

        Materiale =
            await _preventivoRepository.GetMaterialeAsync(
                id!.Value,
                cancellationToken);

        if (Materiale is null ||
            Materiale.IdRigaPreventivo != idRigaPreventivo)
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
            await _preventivoRepository.EliminaMaterialeAsync(
                id!.Value,
                cancellationToken);

            return RedirectToWorkspace(idPreventivo, idRigaPreventivo);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        if (string.IsNullOrWhiteSpace(NuovoMateriale.DescrizioneMateriale))
        {
            ModelState.AddModelError(
                nameof(NuovoMateriale.DescrizioneMateriale),
                "La descrizione del materiale e obbligatoria.");
        }

        NuovoMateriale.IdRigaPreventivo = idRigaPreventivo;

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idMateriale =
            await _preventivoRepository.CreaMaterialeAsync(
                NuovoMateriale,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Materiali",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                id = idMateriale
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

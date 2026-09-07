using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class LavorazioniModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public PreventivoRigaLavorazioneItem? Lavorazione { get; private set; }

    [BindProperty]
    public PreventivoRigaLavorazioneCreateModel NuovaLavorazione { get; set; } = new();

    public LavorazioniModel(IPreventivoRepository preventivoRepository)
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
            NuovaLavorazione = new PreventivoRigaLavorazioneCreateModel
            {
                IdRigaPreventivo = idRigaPreventivo,
                Sequenza = 10,
                Quantita = 1
            };

            return Page();
        }

        Lavorazione =
            await _preventivoRepository.GetLavorazioneAsync(
                id!.Value,
                cancellationToken);

        if (Lavorazione is null ||
            Lavorazione.IdRigaPreventivo != idRigaPreventivo)
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
            await _preventivoRepository.EliminaLavorazioneAsync(
                id!.Value,
                cancellationToken);

            return RedirectToWorkspace(idPreventivo, idRigaPreventivo);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        if (string.IsNullOrWhiteSpace(NuovaLavorazione.DescrizioneLavorazione))
        {
            ModelState.AddModelError(
                nameof(NuovaLavorazione.DescrizioneLavorazione),
                "La descrizione della lavorazione e obbligatoria.");
        }

        NuovaLavorazione.IdRigaPreventivo = idRigaPreventivo;

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idLavorazione =
            await _preventivoRepository.CreaLavorazioneAsync(
                NuovaLavorazione,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Lavorazioni",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                id = idLavorazione
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

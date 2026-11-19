using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public sealed class AnteprimaDistintaModel(IPreventivoRepository repository) : PageModel
{
    public PreventivoRigaDettaglio? Riga { get; private set; }
    public IReadOnlyList<DistintaSnapshotAnteprimaItem> Risultato { get; private set; } = [];

    public async Task<IActionResult> OnPostAsync(
        int idPreventivo, int idRigaPreventivo, int idRevisione, long versioneContenuto,
        CancellationToken cancellationToken)
    {
        var pagina = await OnGetAsync(idPreventivo, idRigaPreventivo, cancellationToken);
        if (pagina is not PageResult) return pagina;
        var anteprima = Risultato.FirstOrDefault();
        if (anteprima is null || anteprima.IdRevisione != idRevisione || anteprima.VersioneContenuto != versioneContenuto)
        {
            ModelState.AddModelError(string.Empty, "La distinta è cambiata. Controlla la nuova anteprima.");
            return Page();
        }
        if (Risultato.Any(x => x.RevisioneGiaApplicata))
            return Page();

        try
        {
            await repository.ApplicaSnapshotAsync(idPreventivo, idRigaPreventivo, idRevisione, versioneContenuto, cancellationToken);
            TempData["MessaggioSuccesso"] = "Distinta aggiornata e valori del preventivo ricalcolati.";
            return RedirectToPage("./Workspace", new { idPreventivo, idRigaPreventivo });
        }
        catch (SqlException ex) when (ex.Number is >= 53802 and <= 53808 or 547 or 2601 or 2627)
        {
            if (ex.Number == 53806)
                return RedirectToPage("./AnteprimaDistinta", new { idPreventivo, idRigaPreventivo });

            ModelState.AddModelError(string.Empty, ex.Number switch
            {
                53803 => "La distinta è cambiata. Riapri l’anteprima.",
                53804 => "Lo stato del preventivo non consente l’aggiornamento della distinta.",
                53805 => "La riga è collegata a un ordine fornitore.",
                53807 => "Ricolloca gli elementi manuali indicati in una nuova anteprima.",
                53808 => "Lo snapshot contiene elementi con allegati.",
                _ => "L’aggiornamento è bloccato da un vincolo sui dati della riga."
            });
            return Page();
        }
    }

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo, int idRigaPreventivo, CancellationToken cancellationToken)
    {
        Riga = await repository.GetRigaAsync(idRigaPreventivo, cancellationToken);
        if (Riga is null || Riga.IdPreventivo != idPreventivo || !Riga.IdArticolo.HasValue)
            return NotFound();

        Risultato = await repository.GetAnteprimaSnapshotAsync(idPreventivo, idRigaPreventivo, cancellationToken);
        return Page();
    }
}

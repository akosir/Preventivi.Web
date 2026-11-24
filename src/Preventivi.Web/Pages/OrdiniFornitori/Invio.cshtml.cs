using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class InvioModel(IOrdineFornitoreRepository repository, IFornitoreRepository fornitori,
    ILogger<InvioModel> logger) : PageModel
{
    [BindProperty] public string? Versione { get; set; }
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<OrdineFornitoreRiga> Righe { get; private set; } = [];
    public bool FornitoreAttivo { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id });
        Versione = Convert.ToBase64String(Ordine.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id });
        var versione = OrdiniFornitoriErrori.LeggiVersione(Versione, ModelState);
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.ConfermaInvioAsync(id, versione, User.Identity?.Name ?? "Sistema", cancellationToken);
            TempData["MessaggioSuccesso"] = "Ordine segnato come inviato. Documento conservato nello storico.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Conferma invio ordine {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return false;
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        FornitoreAttivo = (await fornitori.GetDettaglioAsync(Ordine.IdFornitore, cancellationToken))?.Attivo == true;
        return true;
    }
}

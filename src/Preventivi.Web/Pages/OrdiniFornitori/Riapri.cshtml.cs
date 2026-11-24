using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class RiapriModel(IOrdineFornitoreRepository repository, ILogger<RiapriModel> logger) : PageModel
{
    [BindProperty] public string? Versione { get; set; }
    [BindProperty, StringLength(500, ErrorMessage = "La motivazione può contenere al massimo 500 caratteri.")]
    public string? Motivazione { get; set; }
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public bool HaRicezioni { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!User.IsInRole(AutorizzazioneApplicazione.RuoloAdmin)) return Forbid();
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!string.Equals(Ordine!.Stato, "Inviato", StringComparison.OrdinalIgnoreCase))
            return RedirectToPage("./Dettaglio", new { id });
        Versione = Convert.ToBase64String(Ordine.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!User.IsInRole(AutorizzazioneApplicazione.RuoloAdmin)) return Forbid();
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!string.Equals(Ordine!.Stato, "Inviato", StringComparison.OrdinalIgnoreCase))
            return RedirectToPage("./Dettaglio", new { id });
        var versione = OrdiniFornitoriErrori.LeggiVersione(Versione, ModelState);
        if (string.IsNullOrWhiteSpace(Motivazione))
            ModelState.AddModelError(nameof(Motivazione), "La motivazione amministrativa è obbligatoria.");
        if (HaRicezioni)
            ModelState.AddModelError(string.Empty, "L’ordine contiene ricezioni e non può essere riaperto.");
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.RiapriAsync(id, versione, Motivazione!, User.Identity?.Name ?? "Sistema", cancellationToken);
            TempData["MessaggioSuccesso"] = "Ordine riaperto in Bozza. Motivazione registrata nello storico delle operazioni.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Riapertura ordine {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return false;
        HaRicezioni = (await repository.GetRigheAsync(id, cancellationToken)).Any(x => x.QuantitaRicevuta != 0);
        return true;
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class ModificaModel(IOrdineFornitoreRepository repository, IAnagraficheProduttiveRepository anagrafiche,
    ILogger<ModificaModel> logger) : PageModel
{
    [BindProperty] public OrdineFornitoreFormModel Dati { get; set; } = new();
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<FornitoreAnagraficaLookupItem> Fornitori { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(int? id, CancellationToken cancellationToken)
    {
        if (id.HasValue)
        {
            Ordine = await repository.GetDettaglioAsync(id.Value, cancellationToken);
            if (Ordine is null) return NotFound();
            if (!Ordine.Modificabile) return RedirectToPage("./Dettaglio", new { id });
            Dati = new()
            {
                DataOrdine = Ordine.DataOrdine, IdFornitore = Ordine.IdFornitore,
                Oggetto = Ordine.Oggetto, Note = Ordine.Note, DataConsegnaPrevista = Ordine.DataConsegnaPrevista,
                VersioneRiga = Convert.ToBase64String(Ordine.VersioneRiga)
            };
        }
        Fornitori = await anagrafiche.GetFornitoriAsync(Ordine?.IdFornitore, cancellationToken);
        Dati.DataOrdine ??= DateTime.Today;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int? id, CancellationToken cancellationToken)
    {
        if (id.HasValue)
        {
            Ordine = await repository.GetDettaglioAsync(id.Value, cancellationToken);
            if (Ordine is null) return NotFound();
            if (!Ordine.Modificabile) return RedirectToPage("./Dettaglio", new { id });
        }
        Fornitori = await anagrafiche.GetFornitoriAsync(Ordine?.IdFornitore, cancellationToken);
        var versione = id.HasValue ? OrdiniFornitoriErrori.LeggiVersione(Dati.VersioneRiga, ModelState) : [];
        if (!ModelState.IsValid) return Page();
        try
        {
            var salvato = await repository.SalvaAsync(id, new OrdineFornitoreSalvataggio
            {
                DataOrdine = Dati.DataOrdine!.Value, IdFornitore = Dati.IdFornitore!.Value,
                Oggetto = Dati.Oggetto, Note = Dati.Note, DataConsegnaPrevista = Dati.DataConsegnaPrevista,
                VersioneRiga = versione, Utente = User.Identity?.Name ?? "Sistema"
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Ordine salvato correttamente.";
            return RedirectToPage("./Dettaglio", new { id = salvato });
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Salvataggio ordine {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            return Page();
        }
    }
}

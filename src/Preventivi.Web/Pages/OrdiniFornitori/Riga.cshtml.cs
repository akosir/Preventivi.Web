using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class RigaModel(IOrdineFornitoreRepository repository, IAnagraficheProduttiveRepository anagrafiche,
    ILogger<RigaModel> logger) : PageModel
{
    [BindProperty] public OrdineFornitoreRigaFormModel Dati { get; set; } = new();
    [BindProperty(SupportsGet = true)] public bool Elimina { get; set; }
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public OrdineFornitoreRiga? Riga { get; private set; }
    public IReadOnlyList<MaterialeListItem> Materiali { get; private set; } = [];
    public IReadOnlyList<LavorazioneListItem> Lavorazioni { get; private set; } = [];
    public IReadOnlyList<UnitaMisuraLookupItem> UnitaMisura { get; private set; } = [];
    public IReadOnlyList<OrdineFornitoreDipendenza> Dipendenze { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(int idOrdine, int? id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idOrdine, id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id = idOrdine });
        if (Riga is not null)
        {
            Dati = new()
            {
                RigaNr = Riga.RigaNr, TipoRiga = Riga.TipoRiga, IdMateriale = Riga.IdMateriale, IdLavorazione = Riga.IdLavorazione,
                Descrizione = Riga.Descrizione, UM = Riga.UM, Quantita = Riga.Quantita, PrezzoUnitario = Riga.PrezzoUnitario,
                DataConsegnaPrevista = Riga.DataConsegnaPrevista, Note = Riga.Note,
                VersioneRiga = Convert.ToBase64String(Riga.VersioneRiga)
            };
        }
        else
        {
            var righe = await repository.GetRigheAsync(idOrdine, cancellationToken);
            Dati.RigaNr = righe.Count == 0 ? 1 : righe.Max(x => x.RigaNr) + 1;
        }
        Dati.VersioneOrdine = Convert.ToBase64String(Ordine.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idOrdine, int? id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idOrdine, id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id = idOrdine });
        var versioneOrdine = OrdiniFornitoriErrori.LeggiVersione(Dati.VersioneOrdine, ModelState);
        var versioneRiga = id.HasValue ? OrdiniFornitoriErrori.LeggiVersione(Dati.VersioneRiga, ModelState) : [];
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.SalvaRigaAsync(idOrdine, id, new OrdineFornitoreRigaSalvataggio
            {
                RigaNr = Dati.RigaNr, TipoRiga = Dati.TipoRiga,
                IdMateriale = Dati.TipoRiga == "Materiale" ? Dati.IdMateriale : null,
                IdLavorazione = Dati.TipoRiga == "Lavorazione" ? Dati.IdLavorazione : null,
                Descrizione = Dati.Descrizione, UM = Dati.UM, Quantita = Dati.Quantita, PrezzoUnitario = Dati.PrezzoUnitario,
                DataConsegnaPrevista = Dati.DataConsegnaPrevista, Note = Dati.Note,
                VersioneRiga = versioneRiga, VersioneOrdine = versioneOrdine, Utente = User.Identity?.Name ?? "Sistema"
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Riga salvata e totali aggiornati.";
            return RedirectToPage("./Dettaglio", new { id = idOrdine });
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Salvataggio riga ordine {IdOrdine} {Id} rifiutato", idOrdine, id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    public async Task<IActionResult> OnPostEliminaAsync(int idOrdine, int id, CancellationToken cancellationToken)
    {
        Elimina = true;
        ModelState.Clear();
        if (!await CaricaAsync(idOrdine, id, cancellationToken)) return NotFound();
        if (!Ordine!.Modificabile) return RedirectToPage("./Dettaglio", new { id = idOrdine });
        var versioneOrdine = OrdiniFornitoriErrori.LeggiVersione(Dati.VersioneOrdine, ModelState);
        var versioneRiga = OrdiniFornitoriErrori.LeggiVersione(Dati.VersioneRiga, ModelState);
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.EliminaRigaAsync(idOrdine, id, versioneOrdine, versioneRiga, User.Identity?.Name ?? "Sistema", cancellationToken);
            TempData["MessaggioSuccesso"] = "Riga eliminata e totali aggiornati.";
            return RedirectToPage("./Dettaglio", new { id = idOrdine });
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number))
        {
            logger.LogWarning(exception, "Eliminazione riga ordine {IdOrdine} {Id} rifiutata", idOrdine, id);
            ModelState.AddModelError(string.Empty, OrdiniFornitoriErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(idOrdine, id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idOrdine, int? id, CancellationToken cancellationToken)
    {
        Ordine = await repository.GetDettaglioAsync(idOrdine, cancellationToken);
        if (Ordine is null) return false;
        if (id.HasValue)
        {
            Riga = (await repository.GetRigheAsync(idOrdine, cancellationToken))
                .SingleOrDefault(x => x.IdRigaOrdineFornitore == id.Value);
            if (Riga is null) return false;
        }
        if (!Ordine.Modificabile) return true;
        Materiali = (await anagrafiche.GetMaterialiAsync(cancellationToken: cancellationToken))
            .Where(x => x.Attivo || x.IdMateriale == Riga?.IdMateriale).ToArray();
        Lavorazioni = (await anagrafiche.GetLavorazioniAsync(cancellationToken: cancellationToken))
            .Where(x => x.Attiva || x.IdLavorazione == Riga?.IdLavorazione).ToArray();
        UnitaMisura = await anagrafiche.GetUnitaMisuraAsync(cancellationToken: cancellationToken);
        if (Elimina && id.HasValue)
            Dipendenze = await repository.GetDipendenzeAsync(idOrdine, id, cancellationToken);
        return true;
    }
}

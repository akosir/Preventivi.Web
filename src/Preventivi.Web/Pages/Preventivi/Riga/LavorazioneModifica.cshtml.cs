using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class LavorazioneModificaModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public LavorazioneModificaModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public PreventivoRigaLavorazioneItem? Lavorazione { get; private set; }
    public IReadOnlyList<FornitoreLookupItem> Fornitori { get; private set; }
        = Array.Empty<FornitoreLookupItem>();

    [BindProperty]
    public PreventivoRigaLavorazioneUpdateModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo, int idRigaPreventivo, int idComponente, int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, idComponente, id, cancellationToken))
            return NotFound();

        Dati = new PreventivoRigaLavorazioneUpdateModel
        {
            IdRigaLavPrev = Lavorazione!.IdRigaLavPrev,
            DescrizioneLavorazione = Lavorazione.DescrizioneLavorazione,
            Sequenza = Lavorazione.Sequenza,
            TempoSetupMin = Lavorazione.TempoSetupMin,
            TempoPezzoMin = Lavorazione.TempoPezzoMin,
            Quantita = Lavorazione.Quantita,
            CostoOrario = Lavorazione.CostoOrario,
            CostoFisso = Lavorazione.CostoFisso,
            DaAcquistareEsterno = Lavorazione.DaAcquistareEsterno,
            IdFornitoreSuggerito = Lavorazione.IdFornitoreSuggerito
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idPreventivo, int idRigaPreventivo, int idComponente, int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, idComponente, id, cancellationToken))
            return NotFound();

        Dati.IdRigaLavPrev = id;
        if (string.IsNullOrWhiteSpace(Dati.DescrizioneLavorazione))
            ModelState.AddModelError("Dati.DescrizioneLavorazione", "Inserire la descrizione della lavorazione.");
        if (Dati.TempoSetupMin < 0 || Dati.TempoPezzoMin < 0 || Dati.Quantita < 0 ||
            Dati.CostoOrario < 0 || Dati.CostoFisso < 0)
            ModelState.AddModelError(string.Empty, "Tempi, quantita e costi non possono essere negativi.");
        if (Dati.IdFornitoreSuggerito is > 0 && Fornitori.All(x => x.IdFornitore != Dati.IdFornitoreSuggerito))
            ModelState.AddModelError("Dati.IdFornitoreSuggerito", "Il fornitore selezionato non e disponibile.");

        if (!ModelState.IsValid)
            return Page();

        await _repository.AggiornaLavorazioneAsync(Dati, cancellationToken);
        return RedirectToPage("/Preventivi/Riga/Lavorazioni", new
        {
            modo = "dettaglio", idPreventivo, idRigaPreventivo, idComponente, id
        });
    }

    private async Task<bool> CaricaContestoAsync(
        int idPreventivo, int idRigaPreventivo, int idComponente, int id,
        CancellationToken cancellationToken)
    {
        var riga = await _repository.GetRigaAsync(idRigaPreventivo, cancellationToken);
        var componente = await _repository.GetComponenteAsync(idComponente, cancellationToken);
        Lavorazione = await _repository.GetLavorazioneAsync(id, cancellationToken);
        Fornitori = await _repository.GetFornitoriAsync(cancellationToken);
        return riga?.IdPreventivo == idPreventivo &&
               componente?.IdRigaPreventivo == idRigaPreventivo &&
               Lavorazione?.IdRigaPreventivo == idRigaPreventivo &&
               Lavorazione.IdRigaCompPrev == idComponente;
    }
}

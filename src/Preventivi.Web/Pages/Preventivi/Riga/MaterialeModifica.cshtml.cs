using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class MaterialeModificaModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public MaterialeModificaModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public PreventivoRigaMaterialeItem? Materiale { get; private set; }
    public IReadOnlyList<FornitoreLookupItem> Fornitori { get; private set; }
        = Array.Empty<FornitoreLookupItem>();

    [BindProperty]
    public PreventivoRigaMaterialeUpdateModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo, int idRigaPreventivo, int idComponente, int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, idComponente, id, cancellationToken))
            return NotFound();

        Dati = new PreventivoRigaMaterialeUpdateModel
        {
            IdRigaMatPrev = Materiale!.IdRigaMatPrev,
            DescrizioneMateriale = Materiale.DescrizioneMateriale,
            TipoMateriale = Materiale.TipoMateriale,
            UM = Materiale.UM,
            Quantita = Materiale.Quantita,
            CostoUnitario = Materiale.CostoUnitario,
            DaAcquistare = Materiale.DaAcquistare,
            IdFornitoreSuggerito = Materiale.IdFornitoreSuggerito
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idPreventivo, int idRigaPreventivo, int idComponente, int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, idComponente, id, cancellationToken))
            return NotFound();

        Dati.IdRigaMatPrev = id;
        if (string.IsNullOrWhiteSpace(Dati.DescrizioneMateriale))
            ModelState.AddModelError("Dati.DescrizioneMateriale", "Inserire la descrizione del materiale.");
        if (Dati.Quantita < 0)
            ModelState.AddModelError("Dati.Quantita", "La quantita non puo essere negativa.");
        if (Dati.CostoUnitario < 0)
            ModelState.AddModelError("Dati.CostoUnitario", "Il costo unitario non puo essere negativo.");
        if (Dati.IdFornitoreSuggerito is > 0 && Fornitori.All(x => x.IdFornitore != Dati.IdFornitoreSuggerito))
            ModelState.AddModelError("Dati.IdFornitoreSuggerito", "Il fornitore selezionato non e disponibile.");

        if (!ModelState.IsValid)
            return Page();

        await _repository.AggiornaMaterialeAsync(Dati, cancellationToken);
        return RedirectToPage("/Preventivi/Riga/Materiali", new
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
        Materiale = await _repository.GetMaterialeAsync(id, cancellationToken);
        Fornitori = await _repository.GetFornitoriAsync(cancellationToken);
        return riga?.IdPreventivo == idPreventivo &&
               componente?.IdRigaPreventivo == idRigaPreventivo &&
               Materiale?.IdRigaPreventivo == idRigaPreventivo &&
               Materiale.IdRigaCompPrev == idComponente;
    }
}

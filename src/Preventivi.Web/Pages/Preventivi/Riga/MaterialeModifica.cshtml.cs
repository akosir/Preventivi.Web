using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class MaterialeModificaModel : PageModel
{
    private readonly IPreventivoRepository _repository;
    private readonly IAnagraficheProduttiveRepository _anagraficheRepository;

    public MaterialeModificaModel(IPreventivoRepository repository, IAnagraficheProduttiveRepository anagraficheRepository)
    {
        _repository = repository;
        _anagraficheRepository = anagraficheRepository;
    }

    public PreventivoRigaMaterialeItem? Materiale { get; private set; }
    public IReadOnlyList<FornitoreAnagraficaLookupItem> Fornitori { get; private set; }
        = Array.Empty<FornitoreAnagraficaLookupItem>();

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
        if (Dati.IdFornitoreSuggerito.HasValue && Fornitori.All(x => x.IdFornitore != Dati.IdFornitoreSuggerito ||
                (!x.Attivo && x.IdFornitore != Materiale!.IdFornitoreSuggerito)))
            ModelState.AddModelError("Dati.IdFornitoreSuggerito", "Il fornitore selezionato non e disponibile.");

        global::Preventivi.Web.UI.ValidazioneLunghezzeTesto.ValidaLunghezzeTesto(ModelState, Dati, "Dati");
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
        Fornitori = await _anagraficheRepository.GetFornitoriAsync(Materiale?.IdFornitoreSuggerito, cancellationToken);
        return riga?.IdPreventivo == idPreventivo &&
               componente?.IdRigaPreventivo == idRigaPreventivo &&
               Materiale?.IdRigaPreventivo == idRigaPreventivo &&
               Materiale.IdRigaCompPrev == idComponente;
    }
}

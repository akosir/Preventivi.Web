using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class ComponenteModificaModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public ComponenteModificaModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    [BindProperty]
    public PreventivoRigaComponenteUpdateModel Dati { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo,
        int idRigaPreventivo,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, id, cancellationToken))
            return NotFound();

        Dati = new PreventivoRigaComponenteUpdateModel
        {
            IdRigaCompPrev = Componente!.IdRigaCompPrev,
            DescrizioneNodo = Componente.DescrizioneNodo,
            QuantitaBase = Componente.QuantitaBase,
            OrdineVisualizzazione = Componente.OrdineVisualizzazione
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idPreventivo,
        int idRigaPreventivo,
        int id,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, id, cancellationToken))
            return NotFound();

        Dati.IdRigaCompPrev = id;
        if (string.IsNullOrWhiteSpace(Dati.DescrizioneNodo))
            ModelState.AddModelError("Dati.DescrizioneNodo", "Inserire la descrizione del componente.");
        if (Dati.QuantitaBase <= 0)
            ModelState.AddModelError("Dati.QuantitaBase", "La quantita base deve essere maggiore di zero.");

        if (!ModelState.IsValid)
            return Page();

        await _repository.AggiornaComponenteAsync(Dati, cancellationToken);

        return RedirectToPage("/Preventivi/Riga/Componenti", new
        {
            modo = "dettaglio",
            idPreventivo,
            idRigaPreventivo,
            id
        });
    }

    private async Task<bool> CaricaContestoAsync(
        int idPreventivo,
        int idRigaPreventivo,
        int id,
        CancellationToken cancellationToken)
    {
        var riga = await _repository.GetRigaAsync(idRigaPreventivo, cancellationToken);
        Componente = await _repository.GetComponenteAsync(id, cancellationToken);
        return riga?.IdPreventivo == idPreventivo &&
               Componente?.IdRigaPreventivo == idRigaPreventivo;
    }
}

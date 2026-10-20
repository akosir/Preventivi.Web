using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class ModificaModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public ModificaModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public PreventivoDettaglio? Preventivo { get; private set; }
    public PreventivoRigaDettaglio? RigaCorrente { get; private set; }

    [BindProperty]
    public PreventivoRigaUpdateModel Riga { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(
        int idPreventivo,
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, cancellationToken))
        {
            return NotFound();
        }

        Riga = new PreventivoRigaUpdateModel
        {
            IdRigaPreventivo = RigaCorrente!.IdRigaPreventivo,
            RigaNr = RigaCorrente.RigaNr,
            DescrizioneVoce = RigaCorrente.DescrizioneVoce,
            Quantita = RigaCorrente.Quantita,
            PrezzoUnitarioVendita = RigaCorrente.PrezzoUnitarioVendita,
            Note = RigaCorrente.Note,
            MarkupPerc = RigaCorrente.MarkupPerc,
            PrezzoManuale = RigaCorrente.PrezzoManuale,
            CostoUnitarioLibero = RigaCorrente.CostoUnitarioLibero
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        int idPreventivo,
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(idPreventivo, idRigaPreventivo, cancellationToken))
        {
            return NotFound();
        }

        Riga.IdRigaPreventivo = idRigaPreventivo;

        if (Riga.RigaNr <= 0)
            ModelState.AddModelError("Riga.RigaNr", "Il numero riga deve essere maggiore di zero.");
        if (string.IsNullOrWhiteSpace(Riga.DescrizioneVoce))
            ModelState.AddModelError("Riga.DescrizioneVoce", "Inserire la descrizione della riga.");
        if (Riga.Quantita <= 0)
            ModelState.AddModelError("Riga.Quantita", "La quantita deve essere maggiore di zero.");
        if (RigaCorrente!.CostoUnitarioLibero.HasValue && Riga.CostoUnitarioLibero is null)
            ModelState.AddModelError("Riga.CostoUnitarioLibero", "Inserire il costo unitario della riga libera.");

        if (!ModelState.IsValid)
        {
            return Page();
        }

        await _repository.AggiornaRigaAsync(Riga, cancellationToken);

        return RedirectToPage("/Preventivi/Riga/Workspace", new { idPreventivo, idRigaPreventivo });
    }

    private async Task<bool> CaricaContestoAsync(
        int idPreventivo,
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        Preventivo = await _repository.GetDettaglioAsync(idPreventivo, cancellationToken);
        RigaCorrente = await _repository.GetRigaAsync(idRigaPreventivo, cancellationToken);
        return Preventivo is not null && RigaCorrente?.IdPreventivo == idPreventivo;
    }
}

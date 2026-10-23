using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
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
    public IReadOnlyList<TipoRigaPreventivoItem> TipiRiga { get; private set; }
        = Array.Empty<TipoRigaPreventivoItem>();
    public IReadOnlyList<ArticoloLookupItem> Articoli { get; private set; }
        = Array.Empty<ArticoloLookupItem>();
    public IReadOnlyList<ModelloCicloLookupItem> ModelliCiclo { get; private set; }
        = Array.Empty<ModelloCicloLookupItem>();

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

        await CaricaTipiRigaAsync(cancellationToken);
        await CaricaLookupAsync(cancellationToken);

        Riga = new PreventivoRigaUpdateModel
        {
            IdRigaPreventivo = RigaCorrente!.IdRigaPreventivo,
            IdTipoRiga = RigaCorrente.IdTipoRiga,
            IdArticolo = RigaCorrente.IdArticolo,
            IdModelloCiclo = RigaCorrente.IdModelloCiclo,
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

        await CaricaTipiRigaAsync(cancellationToken);
        await CaricaLookupAsync(cancellationToken);

        Riga.IdRigaPreventivo = idRigaPreventivo;

        var tipoRiga = TipiRiga.FirstOrDefault(
            tipo => tipo.IdTipoRiga == Riga.IdTipoRiga);

        if (Riga.RigaNr <= 0)
            ModelState.AddModelError("Riga.RigaNr", "Il numero riga deve essere maggiore di zero.");
        if (tipoRiga is null)
            ModelState.AddModelError("Riga.IdTipoRiga", "Selezionare un tipo riga disponibile.");
        if (string.IsNullOrWhiteSpace(Riga.DescrizioneVoce))
            ModelState.AddModelError("Riga.DescrizioneVoce", "Inserire la descrizione della riga.");
        if (Riga.Quantita <= 0)
            ModelState.AddModelError("Riga.Quantita", "La quantita deve essere maggiore di zero.");
        var richiedeCostoLibero =
            tipoRiga?.RigaLibera == true && tipoRiga.RigaArticolo == false;

        if (richiedeCostoLibero && Riga.CostoUnitarioLibero is null)
            ModelState.AddModelError("Riga.CostoUnitarioLibero", "Inserire il costo unitario della riga libera.");
        if (!richiedeCostoLibero)
            Riga.CostoUnitarioLibero = null;

        if (tipoRiga?.RigaArticolo == true)
        {
            if (tipoRiga.ObbligaArticolo && !Riga.IdArticolo.HasValue)
                ModelState.AddModelError("Riga.IdArticolo", "Selezionare l'articolo.");
            else if (Riga.IdArticolo.HasValue &&
                     Articoli.All(articolo => articolo.IdArticolo != Riga.IdArticolo.Value))
                ModelState.AddModelError("Riga.IdArticolo", "L'articolo selezionato non e disponibile.");

            if (Riga.IdModelloCiclo.HasValue &&
                ModelliCiclo.All(modello => modello.IdModelloCiclo != Riga.IdModelloCiclo.Value))
                ModelState.AddModelError("Riga.IdModelloCiclo", "Il modello ciclo selezionato non e disponibile.");
        }
        else
        {
            Riga.IdArticolo = null;
            Riga.IdModelloCiclo = null;
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _repository.AggiornaRigaAsync(Riga, cancellationToken);
        }
        catch (SqlException exception) when (exception.Number is 52004 or 52015 or 52016 or 52017 or 2601 or 2627)
        {
            ModelState.AddModelError(
                string.Empty,
                exception.Number switch
                {
                    52004 => "La riga preventivo non e piu disponibile.",
                    52015 => "Il tipo riga selezionato non e piu disponibile.",
                    52016 => "L'articolo selezionato non e disponibile.",
                    52017 => "Il modello ciclo selezionato non e disponibile.",
                    _ => "Il numero riga e gia utilizzato nel preventivo."
                });
            return Page();
        }

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

    private async Task CaricaTipiRigaAsync(CancellationToken cancellationToken)
    {
        TipiRiga = await _repository.GetTipiRigaAsync(cancellationToken);
    }

    private async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        Articoli = await _repository.CercaArticoliAsync(null, cancellationToken);
        ModelliCiclo = await _repository.GetModelliCicloAsync(cancellationToken);
    }
}

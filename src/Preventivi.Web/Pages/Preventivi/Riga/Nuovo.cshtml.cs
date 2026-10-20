using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class NuovoModel : PageModel
{
    private readonly IPreventivoRepository _preventivoRepository;

    public NuovoModel(IPreventivoRepository preventivoRepository)
    {
        _preventivoRepository = preventivoRepository;
    }

    [BindProperty(SupportsGet = true)]
    public int IdPreventivo { get; set; }

    [BindProperty]
    public PreventivoRigaCreateModel Riga { get; set; } = new();

    public IReadOnlyList<TipoRigaPreventivoItem> TipiRiga { get; private set; }
        = Array.Empty<TipoRigaPreventivoItem>();

    public IReadOnlyList<ArticoloLookupItem> Articoli { get; private set; }
        = Array.Empty<ArticoloLookupItem>();

    public IReadOnlyList<ModelloCicloLookupItem> ModelliCiclo { get; private set; }
        = Array.Empty<ModelloCicloLookupItem>();

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        var preventivo =
            await _preventivoRepository.GetDettaglioAsync(
                IdPreventivo,
                cancellationToken);

        if (preventivo is null)
        {
            return NotFound();
        }

        await CaricaTipiAsync(cancellationToken);
        await CaricaLookupAsync(cancellationToken);

        Riga = new PreventivoRigaCreateModel
        {
            IdPreventivo = IdPreventivo,
            Quantita = 1,
            MarkupPerc = preventivo.MarkupPercDefault,
            IdTipoRiga = TipiRiga.FirstOrDefault()?.IdTipoRiga ?? 0
        };

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0)
        {
            return BadRequest();
        }

        Riga.IdPreventivo = IdPreventivo;

        await CaricaTipiAsync(cancellationToken);
        await CaricaLookupAsync(cancellationToken);

        var tipoRiga =
            TipiRiga.FirstOrDefault(
                tipo => tipo.IdTipoRiga == Riga.IdTipoRiga);

        if (string.IsNullOrWhiteSpace(Riga.DescrizioneVoce))
        {
            ModelState.AddModelError(
                "Riga.DescrizioneVoce",
                "Inserire la descrizione della riga.");
        }

        if (Riga.IdTipoRiga <= 0)
        {
            ModelState.AddModelError(
                "Riga.IdTipoRiga",
                "Selezionare il tipo riga.");
        }
        else if (tipoRiga is null)
        {
            ModelState.AddModelError(
                "Riga.IdTipoRiga",
                "Il tipo riga selezionato non è disponibile.");
        }

        if (tipoRiga?.RigaLibera == true && Riga.CostoUnitarioLibero is null)
        {
            ModelState.AddModelError(
                "Riga.CostoUnitarioLibero",
                "Inserire il costo unitario della riga libera.");
        }

        if (tipoRiga?.RigaLibera == false)
        {
            Riga.CostoUnitarioLibero = null;
        }

        if (Riga.Quantita <= 0)
        {
            ModelState.AddModelError(
                "Riga.Quantita",
                "La quantità deve essere maggiore di zero.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idRigaPreventivo =
            await _preventivoRepository.CreaRigaAsync(
                Riga,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Workspace",
            new
            {
                idPreventivo = IdPreventivo,
                idRigaPreventivo
            });
    }

    private async Task CaricaTipiAsync(CancellationToken cancellationToken)
    {
        TipiRiga =
            await _preventivoRepository.GetTipiRigaAsync(cancellationToken);
    }

    private async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        Articoli = await _preventivoRepository.CercaArticoliAsync(
            null,
            cancellationToken);
        ModelliCiclo = await _preventivoRepository.GetModelliCicloAsync(
            cancellationToken);
    }
}

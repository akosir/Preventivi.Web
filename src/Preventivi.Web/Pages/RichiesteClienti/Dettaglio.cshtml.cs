using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.RichiesteClienti;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.RichiesteClienti;

public class DettaglioModel : PageModel
{
    private readonly IRichiestaClienteRepository _repository;
    private readonly IAllegatoRepository _allegatoRepository;

    public DettaglioModel(
        IRichiestaClienteRepository repository,
        IAllegatoRepository allegatoRepository)
    {
        _repository = repository;
        _allegatoRepository = allegatoRepository;
    }

    public RichiestaClienteDettaglio? Richiesta { get; private set; }
    public IReadOnlyList<RichiestaClientePreventivoItem> Preventivi { get; private set; }
        = Array.Empty<RichiestaClientePreventivoItem>();
    public IReadOnlyList<RichiestaClienteCampionaturaItem> Campionature { get; private set; }
        = Array.Empty<RichiestaClienteCampionaturaItem>();
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return NotFound();
        }

        Richiesta = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Richiesta is null)
        {
            return NotFound();
        }

        Preventivi = await _repository.GetPreventiviAsync(id, cancellationToken);
        Campionature = await _repository.GetCampionatureAsync(id, cancellationToken);
        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(
                AllegatoEntita.RichiesteClienti,
                id,
                cancellationToken),
            ReturnUrl = Url.Page("/RichiesteClienti/Dettaglio", new { id })
        };

        return Page();
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Campionature;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Campionature;

public class DettaglioModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly IAllegatoRepository _allegatoRepository;

    public DettaglioModel(
        ICampionaturaRepository repository,
        IAllegatoRepository allegatoRepository)
    {
        _repository = repository;
        _allegatoRepository = allegatoRepository;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public IReadOnlyList<CampionaturaRilievoListItem> Rilievi { get; private set; } = [];
    public IReadOnlyList<CampionaturaAdeguamentoListItem> Adeguamenti { get; private set; } = [];
    public IReadOnlyList<CampionaturaCorrezioneStatoListItem> CorrezioniStato { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return NotFound();
        }

        Campionatura = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Campionatura is null)
        {
            return NotFound();
        }

        Rilievi = await _repository.GetRilieviAsync(id, cancellationToken);
        Adeguamenti = await _repository.GetAdeguamentiAsync(id, cancellationToken);
        CorrezioniStato = await _repository.GetCorrezioniStatoAsync(id, cancellationToken);

        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(
                AllegatoEntita.Campionature,
                id,
                cancellationToken),
            ReturnUrl = Url.Page("/Campionature/Dettaglio", new { id })
        };

        return Page();
    }
}

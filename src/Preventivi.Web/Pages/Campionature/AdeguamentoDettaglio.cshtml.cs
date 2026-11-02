using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Campionature;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Campionature;

public sealed class AdeguamentoDettaglioModel : PageModel
{
    private readonly ICampionaturaRepository _repository;
    private readonly IAllegatoRepository _allegatoRepository;

    public AdeguamentoDettaglioModel(
        ICampionaturaRepository repository,
        IAllegatoRepository allegatoRepository)
    {
        _repository = repository;
        _allegatoRepository = allegatoRepository;
    }

    public CampionaturaDettaglio? Campionatura { get; private set; }
    public CampionaturaAdeguamentoDettaglio? Adeguamento { get; private set; }
    public AllegatiGridModel Allegati { get; private set; } = new();
    public bool PuoGestirePreventivi { get; private set; }

    public async Task<IActionResult> OnGetAsync(
        int idCampionatura,
        int id,
        CancellationToken cancellationToken)
    {
        if (idCampionatura <= 0 || id <= 0)
            return NotFound();

        Campionatura = await _repository.GetDettaglioAsync(idCampionatura, cancellationToken);
        Adeguamento = await _repository.GetAdeguamentoAsync(id, cancellationToken);

        if (Campionatura is null || Adeguamento?.IdCampionatura != idCampionatura)
            return NotFound();

        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(
                AllegatoEntita.CampionatureAdeguamenti,
                id,
                cancellationToken)
        };
        PuoGestirePreventivi = AutorizzazioneApplicazione.PuoAccedereAlPermesso(
            User,
            PermessiApplicazione.Preventivi);
        return Page();
    }
}

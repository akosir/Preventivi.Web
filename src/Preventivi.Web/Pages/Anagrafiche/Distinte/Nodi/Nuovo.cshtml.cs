using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Nodi;

public sealed class NuovoModel : PageModel
{
    private readonly IArticoloRepository _articoli;
    private readonly IDistintaBaseRepository _repository;
    private readonly ILogger<NuovoModel> _logger;
    public NuovoModel(IArticoloRepository articoli, IDistintaBaseRepository repository, ILogger<NuovoModel> logger) { _articoli = articoli; _repository = repository; _logger = logger; }

    [BindProperty] public DistintaNodoFormModel Dati { get; set; } = new();
    public ArticoloDettaglio? Articolo { get; private set; }
    public DistintaNodoDettaglio? Padre { get; private set; }

    public async Task<IActionResult> OnGetAsync(int idArticolo, int? idPadre, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idArticolo, idPadre, cancellationToken)) return NotFound();
        Dati.IdNodoPadre = idPadre;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int idArticolo, int? idPadre, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(idArticolo, idPadre, cancellationToken)) return NotFound();
        Dati.IdNodoPadre = idPadre;
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await _repository.CreaNodoAsync(new DistintaNodoCreateModel
            {
                IdArticolo = idArticolo, IdNodoPadre = idPadre, IdTipoNodo = Dati.IdTipoNodo!.Value,
                CodiceNodo = Dati.CodiceNodo, DescrizioneNodo = Dati.DescrizioneNodo,
                QuantitaBase = Dati.QuantitaBase, OrdineVisualizzazione = Dati.OrdineVisualizzazione,
                Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema"
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Nodo distinta creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione nodo distinta rifiutata");
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int idArticolo, int? idPadre, CancellationToken cancellationToken)
    {
        if (idArticolo <= 0) return false;
        Articolo = await _articoli.GetDettaglioAsync(idArticolo, cancellationToken);
        if (Articolo is null) return false;
        if (idPadre is > 0)
        {
            Padre = await _repository.GetNodoAsync(idPadre.Value, cancellationToken);
            if (Padre is null || Padre.IdArticolo != idArticolo) return false;
        }
        ViewData["TipiNodo"] = await _repository.GetTipiNodoAsync(cancellationToken: cancellationToken);
        ViewData["ConsentiPadre"] = false;
        return true;
    }
}

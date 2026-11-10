using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Nodi;

public sealed class DettaglioModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly IAllegatoRepository _allegati;
    private readonly ILogger<DettaglioModel> _logger;
    public DettaglioModel(IDistintaBaseRepository repository, IAllegatoRepository allegati, ILogger<DettaglioModel> logger) { _repository = repository; _allegati = allegati; _logger = logger; }

    public DistintaNodoDettaglio? Nodo { get; private set; }
    public IReadOnlyList<DistintaNodoItem> Figli { get; private set; } = [];
    public IReadOnlyList<DistintaMaterialeDettaglio> Materiali { get; private set; } = [];
    public IReadOnlyList<DistintaLavorazioneDettaglio> Lavorazioni { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) => await CaricaAsync(id, cancellationToken) ? Page() : NotFound();
    public Task<IActionResult> OnPostAttivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) => ImpostaStatoAsync(id, true, versioneRigaBase64, cancellationToken);
    public Task<IActionResult> OnPostDisattivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) => ImpostaStatoAsync(id, false, versioneRigaBase64, cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(int id, bool attivo, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        byte[] versione;
        try { versione = Convert.FromBase64String(versioneRigaBase64); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); await CaricaAsync(id, cancellationToken); return Page(); }
        try
        {
            await _repository.ImpostaStatoNodoAsync(new DistintaNodoStatoModel { IdNodoDistinta = id, Attivo = attivo, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken);
            TempData["MessaggioSuccesso"] = attivo ? "Nodo riattivato correttamente." : "Nodo disattivato correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Cambio stato nodo distinta {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            await CaricaAsync(id, cancellationToken);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Nodo = await _repository.GetNodoAsync(id, cancellationToken);
        if (Nodo is null) return false;
        var nodi = await _repository.GetNodiAsync(Nodo.IdArticolo, cancellationToken);
        Figli = nodi.Where(n => n.IdNodoPadre == id).ToArray();
        Materiali = await _repository.GetMaterialiAsync(id, cancellationToken);
        Lavorazioni = await _repository.GetLavorazioniAsync(id, cancellationToken);
        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegati.GetElencoAsync(AllegatoEntita.DistintaBaseNodi, id, cancellationToken),
            ReturnUrl = Url.Page("/Anagrafiche/Distinte/Nodi/Dettaglio", new { id })
        };
        return true;
    }
}

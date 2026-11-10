using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Materiali;

public sealed class ModificaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly IAllegatoRepository _allegati;
    private readonly ILogger<ModificaModel> _logger;
    public ModificaModel(IDistintaBaseRepository repository, IAllegatoRepository allegati, ILogger<ModificaModel> logger) { _repository = repository; _allegati = allegati; _logger = logger; }
    [BindProperty] public DistintaMaterialeFormModel Dati { get; set; } = new();
    public DistintaMaterialeDettaglio? Materiale { get; private set; }
    public DistintaNodoDettaglio? Nodo { get; private set; }
    public AllegatiGridModel Allegati { get; private set; } = new();
    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new DistintaMaterialeFormModel { IdMateriale = Materiale!.IdMateriale, Quantita = Materiale.Quantita, CoeffScartoPerc = Materiale.CoeffScartoPerc, CostoUnitario = Materiale.CostoUnitario, Note = Materiale.Note, VersioneRigaBase64 = Convert.ToBase64String(Materiale.VersioneRiga) };
        return Page();
    }
    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        var versione = LeggiVersione();
        if (!ModelState.IsValid) return Page();
        try
        {
            await _repository.AggiornaMaterialeAsync(new DistintaMaterialeUpdateModel { IdDistintaMateriale = id, IdNodoDistinta = Materiale!.IdNodoDistinta, IdMateriale = Dati.IdMateriale!.Value, Quantita = Dati.Quantita, CoeffScartoPerc = Dati.CoeffScartoPerc, CostoUnitario = Dati.CostoUnitario, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Materiale distinta aggiornato correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number)) { _logger.LogWarning(exception, "Aggiornamento materiale distinta {Id} rifiutato", id); ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number)); return Page(); }
    }
    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false; Materiale = await _repository.GetMaterialeAsync(id, cancellationToken); if (Materiale is null) return false; Nodo = await _repository.GetNodoAsync(Materiale.IdNodoDistinta, cancellationToken); if (Nodo is null) return false;
        ViewData["MaterialiLookup"] = await _repository.GetMaterialiLookupAsync(Materiale.IdMateriale, cancellationToken);
        Allegati = new AllegatiGridModel { Allegati = await _allegati.GetElencoAsync(AllegatoEntita.DistintaMateriali, id, cancellationToken), ReturnUrl = Url.Page("/Anagrafiche/Distinte/Materiali/Modifica", new { id }) };
        return true;
    }
    private byte[] LeggiVersione() { try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); } catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; } }
}

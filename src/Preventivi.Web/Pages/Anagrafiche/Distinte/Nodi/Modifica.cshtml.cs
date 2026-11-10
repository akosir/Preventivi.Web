using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Nodi;

public sealed class ModificaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly ILogger<ModificaModel> _logger;
    public ModificaModel(IDistintaBaseRepository repository, ILogger<ModificaModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public DistintaNodoFormModel Dati { get; set; } = new();
    public DistintaNodoDettaglio? Nodo { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new DistintaNodoFormModel
        {
            IdNodoPadre = Nodo!.IdNodoPadre, IdTipoNodo = Nodo.IdTipoNodo, CodiceNodo = Nodo.CodiceNodo,
            DescrizioneNodo = Nodo.DescrizioneNodo, QuantitaBase = Nodo.QuantitaBase,
            OrdineVisualizzazione = Nodo.OrdineVisualizzazione, Note = Nodo.Note,
            VersioneRigaBase64 = Convert.ToBase64String(Nodo.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        var versione = LeggiVersione();
        if (!ModelState.IsValid) return Page();
        try
        {
            await _repository.AggiornaNodoAsync(new DistintaNodoUpdateModel
            {
                IdNodoDistinta = id, IdArticolo = Nodo!.IdArticolo, IdNodoPadre = Dati.IdNodoPadre,
                IdTipoNodo = Dati.IdTipoNodo!.Value, CodiceNodo = Dati.CodiceNodo,
                DescrizioneNodo = Dati.DescrizioneNodo, QuantitaBase = Dati.QuantitaBase,
                OrdineVisualizzazione = Dati.OrdineVisualizzazione, Note = Dati.Note,
                Utente = User.Identity?.Name ?? "Sistema", VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Nodo distinta aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento nodo distinta {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Nodo = await _repository.GetNodoAsync(id, cancellationToken);
        if (Nodo is null) return false;
        ViewData["TipiNodo"] = await _repository.GetTipiNodoAsync(Nodo.IdTipoNodo, cancellationToken);
        ViewData["NodiPadre"] = (await _repository.GetNodiAsync(Nodo.IdArticolo, cancellationToken)).Where(n => n.IdNodoDistinta != id && n.Attivo).ToArray();
        ViewData["ConsentiPadre"] = true;
        return true;
    }

    private byte[] LeggiVersione()
    {
        try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; }
    }
}

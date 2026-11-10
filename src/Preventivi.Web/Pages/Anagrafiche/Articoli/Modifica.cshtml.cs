using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

public sealed class ModificaModel : PageModel
{
    private readonly IArticoloRepository _repository;
    private readonly ILogger<ModificaModel> _logger;
    private ArticoloDettaglio? Corrente { get; set; }
    public ModificaModel(IArticoloRepository repository, ILogger<ModificaModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public ArticoloFormModel Dati { get; set; } = new();
    public int IdArticolo { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new ArticoloFormModel
        {
            CodiceArticolo = Corrente!.CodiceArticolo,
            Descrizione = Corrente.Descrizione,
            Versione = Corrente.Versione,
            IdCliente = Corrente.IdCliente,
            NoteTecniche = Corrente.NoteTecniche,
            VersioneRigaBase64 = Convert.ToBase64String(Corrente.VersioneRiga)
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
            await _repository.AggiornaAsync(new ArticoloUpdateModel
            {
                IdArticolo = id,
                CodiceArticolo = Dati.CodiceArticolo,
                Descrizione = Dati.Descrizione,
                Versione = Dati.Versione,
                IdCliente = Dati.IdCliente,
                NoteTecniche = Dati.NoteTecniche,
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Articolo aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (ArticoliSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento articolo {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, ArticoliSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        IdArticolo = id;
        Corrente = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Corrente is null) return false;
        ViewData["Clienti"] = await _repository.GetClientiAsync(Corrente.IdCliente, cancellationToken);
        return true;
    }

    private byte[] LeggiVersione()
    {
        try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; }
    }
}

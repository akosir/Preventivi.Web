using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class ModificaModel : PageModel
{
    private readonly IAnagraficheBaseRepository _repository;
    private readonly ILogger<ModificaModel> _logger;

    public ModificaModel(IAnagraficheBaseRepository repository, ILogger<ModificaModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [BindProperty]
    public AnagraficaBaseFormModel Dati { get; set; } = new();

    public int Id { get; private set; }
    public AnagraficaBasePagina? Pagina { get; private set; }

    public async Task<IActionResult> OnGetAsync(string tipo, int id, CancellationToken cancellationToken)
    {
        if (!CaricaPagina(tipo, id))
        {
            return NotFound();
        }

        var dettaglio = await _repository.GetDettaglioAsync(Pagina!.Tipo, id, cancellationToken);
        if (dettaglio is null)
        {
            return NotFound();
        }

        Dati = new AnagraficaBaseFormModel
        {
            Codice = dettaglio.Codice,
            Descrizione = dettaglio.Descrizione,
            VersioneRigaBase64 = Convert.ToBase64String(dettaglio.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(string tipo, int id, CancellationToken cancellationToken)
    {
        if (!CaricaPagina(tipo, id))
        {
            return NotFound();
        }

        ValidaDati();
        var versione = LeggiVersione();
        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _repository.AggiornaAsync(
                Pagina!.Tipo,
                new AnagraficaBaseUpdateModel
                {
                    Id = id,
                    Codice = Dati.Codice,
                    Descrizione = Dati.Descrizione,
                    Utente = User.Identity?.Name ?? "Sistema",
                    VersioneRiga = versione
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = "Elemento aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { tipo = Pagina.Chiave, id });
        }
        catch (SqlException exception) when (AnagraficheSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento anagrafica {Tipo} {Id} rifiutato", tipo, id);
            ModelState.AddModelError(string.Empty, AnagraficheSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private bool CaricaPagina(string tipo, int id)
    {
        Id = id;
        if (id <= 0 || !AnagraficaBasePagina.TryGet(tipo, out var pagina))
        {
            return false;
        }
        Pagina = pagina;
        return true;
    }

    private byte[] LeggiVersione()
    {
        try
        {
            return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
            return [];
        }
    }

    private void ValidaDati()
    {
        if (Pagina!.MostraCodice && string.IsNullOrWhiteSpace(Dati.Codice))
        {
            ModelState.AddModelError("Dati.Codice", "Il codice e obbligatorio.");
        }
        if (Dati.Descrizione?.Trim().Length > Pagina.LunghezzaDescrizione)
        {
            ModelState.AddModelError("Dati.Descrizione", $"La descrizione puo contenere al massimo {Pagina.LunghezzaDescrizione} caratteri.");
        }
    }
}

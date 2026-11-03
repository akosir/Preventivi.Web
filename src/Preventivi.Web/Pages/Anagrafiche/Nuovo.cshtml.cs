using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class NuovoModel : PageModel
{
    private readonly IAnagraficheBaseRepository _repository;
    private readonly ILogger<NuovoModel> _logger;

    public NuovoModel(IAnagraficheBaseRepository repository, ILogger<NuovoModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [BindProperty]
    public AnagraficaBaseFormModel Dati { get; set; } = new();

    public AnagraficaBasePagina? Pagina { get; private set; }

    public IActionResult OnGet(string tipo) =>
        CaricaPagina(tipo) ? Page() : NotFound();

    public async Task<IActionResult> OnPostAsync(string tipo, CancellationToken cancellationToken)
    {
        if (!CaricaPagina(tipo))
        {
            return NotFound();
        }

        ValidaDati();
        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            var id = await _repository.CreaAsync(
                Pagina!.Tipo,
                new AnagraficaBaseCreateModel
                {
                    Codice = Dati.Codice,
                    Descrizione = Dati.Descrizione,
                    Utente = User.Identity?.Name ?? "Sistema"
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = "Elemento creato correttamente.";
            return RedirectToPage("./Dettaglio", new { tipo = Pagina.Chiave, id });
        }
        catch (SqlException exception) when (AnagraficheSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione anagrafica {Tipo} rifiutata", tipo);
            ModelState.AddModelError(string.Empty, AnagraficheSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private bool CaricaPagina(string tipo)
    {
        if (!AnagraficaBasePagina.TryGet(tipo, out var pagina))
        {
            return false;
        }

        Pagina = pagina;
        return true;
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

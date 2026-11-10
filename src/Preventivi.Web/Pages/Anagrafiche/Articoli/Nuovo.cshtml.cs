using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Articoli;

public sealed class NuovoModel : PageModel
{
    private readonly IArticoloRepository _repository;
    private readonly ILogger<NuovoModel> _logger;
    public NuovoModel(IArticoloRepository repository, ILogger<NuovoModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public ArticoloFormModel Dati { get; set; } = new();
    public async Task OnGetAsync(CancellationToken cancellationToken) => await CaricaLookupAsync(cancellationToken);

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await _repository.CreaAsync(new ArticoloCreateModel
            {
                CodiceArticolo = Dati.CodiceArticolo,
                Descrizione = Dati.Descrizione,
                Versione = Dati.Versione,
                IdCliente = Dati.IdCliente,
                NoteTecniche = Dati.NoteTecniche,
                Utente = User.Identity?.Name ?? "Sistema"
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Articolo creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (ArticoliSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione articolo rifiutata");
            ModelState.AddModelError(string.Empty, ArticoliSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task CaricaLookupAsync(CancellationToken cancellationToken) =>
        ViewData["Clienti"] = await _repository.GetClientiAsync(cancellationToken: cancellationToken);
}

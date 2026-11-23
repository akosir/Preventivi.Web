using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Fornitori;

public sealed class NuovoModel : PageModel
{
    private readonly IFornitoreRepository _repository;
    private readonly ILogger<NuovoModel> _logger;
    public NuovoModel(IFornitoreRepository repository, ILogger<NuovoModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public FornitoreFormModel Dati { get; set; } = new();
    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await _repository.CreaAsync(new FornitoreCreateModel
            {
                CodiceFornitore = Dati.CodiceFornitore,
                RagioneSociale = Dati.RagioneSociale,
                PartitaIVA = Dati.PartitaIVA,
                CodiceFiscale = Dati.CodiceFiscale,
                Indirizzo = Dati.Indirizzo,
                CAP = Dati.CAP,
                Citta = Dati.Citta,
                Provincia = Dati.Provincia,
                Telefono = Dati.Telefono,
                Email = Dati.Email,
                Referente = Dati.Referente,
                Utente = User.Identity?.Name ?? "Sistema"
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Fornitore creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (FornitoriSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione fornitore rifiutata");
            ModelState.AddModelError(string.Empty, FornitoriSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

}

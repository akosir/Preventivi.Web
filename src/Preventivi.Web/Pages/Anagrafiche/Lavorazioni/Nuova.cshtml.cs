using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Lavorazioni;

public sealed class NuovaModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    private readonly ILogger<NuovaModel> _logger;
    public NuovaModel(IAnagraficheProduttiveRepository repository, ILogger<NuovaModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public LavorazioneFormModel Dati { get; set; } = new();
    public async Task OnGetAsync(CancellationToken cancellationToken) => await CaricaLookupAsync(cancellationToken);
    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);
        Valida();
        if (!ModelState.IsValid) return Page();
        try
        {
            var id = await _repository.CreaLavorazioneAsync(CreaModello(), cancellationToken);
            TempData["MessaggioSuccesso"] = "Lavorazione creata correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (AnagraficheProduttiveSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione lavorazione rifiutata");
            ModelState.AddModelError(string.Empty, AnagraficheProduttiveSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }
    private LavorazioneCreateModel CreaModello() => new() { CodiceLavorazione = Dati.CodiceLavorazione, Descrizione = Dati.Descrizione, InternaEsterna = Dati.InternaEsterna, CostoOrarioStandard = Dati.CostoOrarioStandard, TempoSetupMinDefault = Dati.TempoSetupMinDefault, TempoPezzoMinDefault = Dati.TempoPezzoMinDefault, AcquistabileEsterna = Dati.AcquistabileEsterna, IdFornitorePredefinito = Dati.IdFornitorePredefinito, Note = Dati.Note, Utente = User.Identity?.Name ?? "Sistema" };
    private async Task CaricaLookupAsync(CancellationToken cancellationToken) => ViewData["Fornitori"] = await _repository.GetFornitoriAsync(cancellationToken: cancellationToken);
    private void Valida()
    {
        if (Dati.InternaEsterna is not ("Interna" or "Esterna")) ModelState.AddModelError("Dati.InternaEsterna", "Selezionare una tipologia valida.");
        if (!Dati.AcquistabileEsterna && Dati.IdFornitorePredefinito.HasValue) ModelState.AddModelError("Dati.IdFornitorePredefinito", "Il fornitore e ammesso soltanto per lavorazioni acquistabili esternamente.");
    }
}

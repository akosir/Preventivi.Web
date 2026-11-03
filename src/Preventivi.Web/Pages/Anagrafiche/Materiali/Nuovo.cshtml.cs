using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Materiali;

public sealed class NuovoModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    private readonly ILogger<NuovoModel> _logger;

    public NuovoModel(IAnagraficheProduttiveRepository repository, ILogger<NuovoModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [BindProperty] public MaterialeFormModel Dati { get; set; } = new();

    public async Task OnGetAsync(CancellationToken cancellationToken) =>
        await CaricaLookupAsync(cancellationToken);

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        await CaricaLookupAsync(cancellationToken);
        Valida();
        if (!ModelState.IsValid) return Page();

        try
        {
            var id = await _repository.CreaMaterialeAsync(CreaModello(), cancellationToken);
            TempData["MessaggioSuccesso"] = "Materiale creato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (AnagraficheProduttiveSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Creazione materiale rifiutata");
            ModelState.AddModelError(string.Empty, AnagraficheProduttiveSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private MaterialeCreateModel CreaModello() => new()
    {
        CodiceMateriale = Dati.CodiceMateriale,
        Descrizione = Dati.Descrizione,
        IdUM = Dati.IdUM.GetValueOrDefault(),
        TipoMateriale = Dati.TipoMateriale,
        CostoUnitario = Dati.CostoUnitario,
        GestitoAAcquisto = Dati.GestitoAAcquisto,
        IdFornitorePredefinito = Dati.IdFornitorePredefinito,
        Note = Dati.Note,
        Utente = User.Identity?.Name ?? "Sistema"
    };

    private async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        ViewData["UnitaMisura"] = await _repository.GetUnitaMisuraAsync(cancellationToken: cancellationToken);
        ViewData["Fornitori"] = await _repository.GetFornitoriAsync(cancellationToken: cancellationToken);
    }

    private void Valida()
    {
        if (!new[] { "MateriaPrima", "Accessorio", "Semilavorato" }.Contains(Dati.TipoMateriale))
            ModelState.AddModelError("Dati.TipoMateriale", "Selezionare un tipo materiale valido.");
        if (!Dati.GestitoAAcquisto && Dati.IdFornitorePredefinito.HasValue)
            ModelState.AddModelError("Dati.IdFornitorePredefinito", "Il fornitore e ammesso soltanto per materiali gestiti ad acquisto.");
    }
}

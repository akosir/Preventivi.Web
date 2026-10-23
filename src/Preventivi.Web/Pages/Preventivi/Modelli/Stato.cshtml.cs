using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli;

public sealed class StatoModel : PageModel
{
    private readonly IModelloPreventivoRepository _repository;

    public StatoModel(IModelloPreventivoRepository repository)
    {
        _repository = repository;
    }

    [BindProperty(SupportsGet = true)]
    public int Id { get; set; }

    [BindProperty(SupportsGet = true)]
    public bool Attivo { get; set; }

    public ModelloPreventivoDettaglio? Modello { get; private set; }

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        Modello = await _repository.GetDettaglioAsync(Id, cancellationToken);
        return Modello is null ? NotFound() : Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        Modello = await _repository.GetDettaglioAsync(Id, cancellationToken);
        if (Modello is null)
            return NotFound();

        try
        {
            await _repository.ImpostaAttivoAsync(Id, Attivo, cancellationToken);
        }
        catch (SqlException exception) when (exception.Number == 52113)
        {
            return NotFound();
        }

        TempData["MessaggioSuccesso"] = Attivo
            ? "Modello preventivo riattivato correttamente."
            : "Modello preventivo eliminato dalla selezione dei modelli attivi.";

        return RedirectToPage("./Index", new { stato = Attivo ? "attivi" : "nonattivi" });
    }
}

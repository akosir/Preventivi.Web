using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.RichiesteClienti;

namespace Preventivi.Web.Pages.RichiesteClienti;

public class RiattivaModel : PageModel
{
    private readonly IRichiestaClienteRepository _repository;
    private readonly IRichiestaClienteApplicationService _service;
    private readonly ILogger<RiattivaModel> _logger;

    public RiattivaModel(
        IRichiestaClienteRepository repository,
        IRichiestaClienteApplicationService service,
        ILogger<RiattivaModel> logger)
    {
        _repository = repository;
        _service = service;
        _logger = logger;
    }

    [BindProperty]
    public int Id { get; set; }

    [BindProperty]
    public string VersioneRigaBase64 { get; set; } = string.Empty;

    public RichiestaClienteDettaglio? Richiesta { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken))
        {
            return NotFound();
        }

        if (!string.Equals(Richiesta!.Stato, "Annullata", StringComparison.Ordinal))
        {
            return RedirectToPage("./Dettaglio", new { id });
        }

        Id = id;
        VersioneRigaBase64 = Convert.ToBase64String(Richiesta.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(Id, cancellationToken))
        {
            return NotFound();
        }

        byte[] versioneRiga;
        try
        {
            versioneRiga = Convert.FromBase64String(VersioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(
                string.Empty,
                "La richiesta e stata modificata. Ricaricare la pagina e riprovare.");
            return Page();
        }

        try
        {
            await _service.RiattivaAsync(
                Id,
                versioneRiga,
                User.Identity?.Name ?? "Sistema",
                cancellationToken);

            TempData["MessaggioSuccesso"] = "Richiesta cliente riattivata correttamente.";
            return RedirectToPage("./Dettaglio", new { id = Id });
        }
        catch (ArgumentException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return Page();
        }
        catch (SqlException exception) when (exception.Number is 52506 or 52511)
        {
            _logger.LogWarning(exception, "Riattivazione richiesta cliente {Id} rifiutata", Id);
            ModelState.AddModelError(
                string.Empty,
                exception.Number == 52506
                    ? "La richiesta e stata modificata da un altro utente. Ricaricare la pagina."
                    : "La richiesta non e piu annullata e non puo essere riattivata.");
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return false;
        }

        Richiesta = await _repository.GetDettaglioAsync(id, cancellationToken);
        return Richiesta is not null;
    }
}

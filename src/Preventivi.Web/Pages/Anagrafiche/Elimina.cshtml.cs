using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class EliminaModel : PageModel
{
    private readonly IAnagraficheBaseRepository _repository;
    private readonly ILogger<EliminaModel> _logger;

    public EliminaModel(IAnagraficheBaseRepository repository, ILogger<EliminaModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public AnagraficaBasePagina? Pagina { get; private set; }
    public AnagraficaBaseDettaglio? Dettaglio { get; private set; }

    public async Task<IActionResult> OnGetAsync(string tipo, int id, CancellationToken cancellationToken) =>
        await CaricaAsync(tipo, id, cancellationToken) ? Page() : NotFound();

    public async Task<IActionResult> OnPostAsync(
        string tipo,
        int id,
        string versioneRigaBase64,
        CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(tipo, id, cancellationToken))
        {
            return NotFound();
        }

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(versioneRigaBase64);
        }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
            return Page();
        }

        try
        {
            await _repository.EliminaAsync(
                Pagina!.Tipo,
                new AnagraficaBaseDeleteModel { Id = id, VersioneRiga = versione },
                cancellationToken);
            TempData["MessaggioSuccesso"] = "Elemento eliminato correttamente.";
            return RedirectToPage("./Gestione", new { tipo = Pagina.Chiave });
        }
        catch (SqlException exception) when (AnagraficheSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Eliminazione anagrafica {Tipo} {Id} rifiutata", tipo, id);
            ModelState.AddModelError(string.Empty, AnagraficheSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(string tipo, int id, CancellationToken cancellationToken)
    {
        if (!AnagraficaBasePagina.TryGet(tipo, out var pagina) || id <= 0)
        {
            return false;
        }
        Pagina = pagina;
        Dettaglio = await _repository.GetDettaglioAsync(pagina.Tipo, id, cancellationToken);
        return Dettaglio is not null;
    }
}

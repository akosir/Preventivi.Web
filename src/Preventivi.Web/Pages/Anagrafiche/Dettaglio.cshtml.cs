using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche;

public sealed class DettaglioModel : PageModel
{
    private readonly IAnagraficheBaseRepository _repository;
    private readonly ILogger<DettaglioModel> _logger;

    public DettaglioModel(IAnagraficheBaseRepository repository, ILogger<DettaglioModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public AnagraficaBasePagina? Pagina { get; private set; }
    public AnagraficaBaseDettaglio? Dettaglio { get; private set; }

    public async Task<IActionResult> OnGetAsync(string tipo, int id, CancellationToken cancellationToken)
    {
        return await CaricaAsync(tipo, id, cancellationToken) ? Page() : NotFound();
    }

    public async Task<IActionResult> OnPostAttivaAsync(
        string tipo,
        int id,
        string versioneRigaBase64,
        CancellationToken cancellationToken) =>
        await ImpostaStatoAsync(
            tipo,
            id,
            attivo: true,
            versioneRigaBase64,
            cancellationToken);

    public async Task<IActionResult> OnPostDisattivaAsync(
        string tipo,
        int id,
        string versioneRigaBase64,
        CancellationToken cancellationToken) =>
        await ImpostaStatoAsync(
            tipo,
            id,
            attivo: false,
            versioneRigaBase64,
            cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(
        string tipo,
        int id,
        bool attivo,
        string versioneRigaBase64,
        CancellationToken cancellationToken)
    {
        if (!AnagraficaBasePagina.TryGet(tipo, out var pagina) || id <= 0)
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
            await CaricaAsync(tipo, id, cancellationToken);
            return Page();
        }

        try
        {
            await _repository.ImpostaStatoAsync(
                pagina.Tipo,
                new AnagraficaBaseStatoModel
                {
                    Id = id,
                    Attivo = attivo,
                    Utente = User.Identity?.Name ?? "Sistema",
                    VersioneRiga = versione
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = attivo
                ? "Elemento riattivato correttamente."
                : "Elemento disattivato correttamente.";
            return RedirectToPage(new { tipo = pagina.Chiave, id });
        }
        catch (SqlException exception) when (AnagraficheSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Cambio stato anagrafica {Tipo} {Id} rifiutato", tipo, id);
            ModelState.AddModelError(string.Empty, AnagraficheSqlErrori.Messaggio(exception.Number));
            await CaricaAsync(tipo, id, cancellationToken);
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

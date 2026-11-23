using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Fornitori;

public sealed class DettaglioModel : PageModel
{
    private readonly IFornitoreRepository _repository;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly ILogger<DettaglioModel> _logger;

    public DettaglioModel(IFornitoreRepository repository, IAllegatoRepository allegatoRepository, ILogger<DettaglioModel> logger)
    {
        _repository = repository;
        _allegatoRepository = allegatoRepository;
        _logger = logger;
    }

    public FornitoreDettaglio? Fornitore { get; private set; }
    public bool Amministratore => User.IsInRole(global::Preventivi.Web.Sicurezza.AutorizzazioneApplicazione.RuoloAdmin);
    public IReadOnlyList<FornitoreDipendenza> Dipendenze { get; private set; } = [];
    public AllegatiGridModel Allegati { get; private set; } = new();

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken) =>
        await CaricaAsync(id, cancellationToken) ? Page() : NotFound();

    public Task<IActionResult> OnPostAttivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, true, versioneRigaBase64, cancellationToken);

    public Task<IActionResult> OnPostDisattivaAsync(int id, string versioneRigaBase64, CancellationToken cancellationToken) =>
        ImpostaStatoAsync(id, false, versioneRigaBase64, cancellationToken);

    private async Task<IActionResult> ImpostaStatoAsync(int id, bool attivo, string versioneRigaBase64, CancellationToken cancellationToken)
    {
        if (!Amministratore) return Forbid();
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        byte[] versione;
        try { versione = Convert.FromBase64String(versioneRigaBase64 ?? string.Empty); }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
            return Page();
        }

        if (versione.Length != 8)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non è valida. Riaprire la pagina.");
            return Page();
        }
        try
        {
            await _repository.ImpostaStatoAsync(new AnagraficaProduttivaStatoModel
            {
                Id = id,
                Attivo = attivo,
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = attivo ? "Fornitore riattivato correttamente." : "Fornitore disattivato correttamente.";
            return RedirectToPage(new { id });
        }
        catch (SqlException exception) when (FornitoriSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Cambio stato fornitore {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, FornitoriSqlErrori.Messaggio(exception.Number));
            if (!await CaricaAsync(id, cancellationToken)) return NotFound();
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Fornitore = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Fornitore is null) return false;
        Dipendenze = await _repository.GetDipendenzeAsync(id, cancellationToken);
        Allegati = new AllegatiGridModel
        {
            Allegati = await _allegatoRepository.GetElencoAsync(AllegatoEntita.Fornitori, id, cancellationToken),
            ReturnUrl = Url.Page("/Anagrafiche/Fornitori/Dettaglio", new { id })
        };
        return true;
    }
}

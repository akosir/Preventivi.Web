using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte.Revisioni;

[Authorize(Policy = AutorizzazioneApplicazione.PolicyAdmin)]
public sealed class PubblicaModel : PageModel
{
    private readonly IDistintaBaseRepository _repository;
    private readonly ILogger<PubblicaModel> _logger;

    public PubblicaModel(IDistintaBaseRepository repository, ILogger<PubblicaModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [BindProperty]
    public DistintaRevisionePubblicazioneFormModel Dati { get; set; } = new();

    public DistintaRevisioneDettaglio? Revisione { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken))
        {
            return NotFound();
        }

        Dati.VersioneRigaBase64 = Convert.ToBase64String(Revisione!.VersioneRiga);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken))
        {
            return NotFound();
        }

        byte[] versione;
        try
        {
            versione = Convert.FromBase64String(Dati.VersioneRigaBase64);
        }
        catch (FormatException)
        {
            versione = [];
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _repository.PubblicaAsync(
                new DistintaRevisionePubblicaModel
                {
                    IdRevisioneDistinta = id,
                    Motivazione = Dati.Motivazione,
                    Utente = User.Identity?.Name ?? "Sistema",
                    VersioneRiga = versione
                },
                cancellationToken);
            TempData["MessaggioSuccesso"] = "Revisione pubblicata correttamente. La precedente revisione pubblicata e ora superata.";
            return RedirectToPage("../Dettaglio", new { idArticolo = Revisione!.IdArticolo, idRevisione = id });
        }
        catch (SqlException exception) when (DistinteSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Pubblicazione revisione distinta {Id} rifiutata", id);
            ModelState.AddModelError(string.Empty, DistinteSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return false;
        }

        Revisione = await _repository.GetRevisioneAsync(id, cancellationToken);
        return Revisione?.Modificabile == true;
    }
}

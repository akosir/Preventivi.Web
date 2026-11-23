using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Fornitori;

public sealed class ModificaModel : PageModel
{
    private readonly IFornitoreRepository _repository;
    private readonly ILogger<ModificaModel> _logger;
    private FornitoreDettaglio? Corrente { get; set; }
    public ModificaModel(IFornitoreRepository repository, ILogger<ModificaModel> logger) { _repository = repository; _logger = logger; }
    [BindProperty] public FornitoreFormModel Dati { get; set; } = new();
    public int IdFornitore { get; private set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new FornitoreFormModel
        {
            CodiceFornitore = Corrente!.CodiceFornitore,
            RagioneSociale = Corrente!.RagioneSociale,
            PartitaIVA = Corrente!.PartitaIVA,
            CodiceFiscale = Corrente!.CodiceFiscale,
            Indirizzo = Corrente!.Indirizzo,
            CAP = Corrente!.CAP,
            Citta = Corrente!.Citta,
            Provincia = Corrente!.Provincia,
            Telefono = Corrente!.Telefono,
            Email = Corrente!.Email,
            Referente = Corrente!.Referente,
            VersioneRigaBase64 = Convert.ToBase64String(Corrente.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        var versione = LeggiVersione();
        if (versione.Length != 8) ModelState.AddModelError(string.Empty, "La versione dei dati non è valida. Riaprire la pagina.");
        if (!ModelState.IsValid) return Page();
        try
        {
            await _repository.AggiornaAsync(new FornitoreUpdateModel
            {
                IdFornitore = id,
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
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Fornitore aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (FornitoriSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento fornitore {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, FornitoriSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        IdFornitore = id;
        Corrente = await _repository.GetDettaglioAsync(id, cancellationToken);
        if (Corrente is null) return false;
        return true;
    }

    private byte[] LeggiVersione()
    {
        try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); }
        catch (FormatException) { ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina."); return []; }
    }
}

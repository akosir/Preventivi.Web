using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Core.Preventivi;
using Preventivi.Web.Sicurezza;
using Preventivi.Web.UI.Modules.OrdiniFornitori;

namespace Preventivi.Web.Pages.OrdiniFornitori;

[Authorize(Policy = AutorizzazioneApplicazione.PolicyPreventivi)]
[RequestFormLimits(ValueCountLimit = 6000)]
public sealed class GeneraModel(IGenerazioneOrdiniFornitoriRepository repository, IPreventivoRepository preventivi,
    IFornitoreRepository fornitori, ILogger<GeneraModel> logger) : PageModel
{
    [BindProperty(SupportsGet = true)] public int IdPreventivo { get; set; }
    [BindProperty(SupportsGet = true)] public int? IdRigaPreventivo { get; set; }
    [BindProperty] public Guid Richiesta { get; set; }
    [BindProperty] public DateTime DataOrdine { get; set; } = DateTime.Today;
    [BindProperty] public List<AcquistoForm> Elementi { get; set; } = [];
    public PreventivoDettaglio? Preventivo { get; private set; }
    public IReadOnlyList<AcquistoPreventivo> Origini { get; private set; } = [];
    public IReadOnlyList<FornitoreDettaglio> Fornitori { get; private set; } = [];
    public IReadOnlyList<OrdineFornitoreDettaglio> Creati { get; private set; } = [];

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(cancellationToken)) return NotFound();
        Richiesta = Guid.NewGuid();
        Elementi = Origini.Select(s => new AcquistoForm
        {
            Tipo = s.Tipo, IdOrigine = s.IdOrigine, Impronta = s.Impronta,
            IdFornitore = Fornitori.Any(f => f.IdFornitore == s.IdFornitoreSuggerito) ? s.IdFornitoreSuggerito : null,
            Quantita = Math.Max(0, s.Residuo), PrezzoUnitario = s.PrezzoProposto
        }).ToList();
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(cancellationToken)) return NotFound();
        if (Richiesta == Guid.Empty || DataOrdine == default)
            ModelState.AddModelError(string.Empty, "Specificare una data valida e riaprire l’anteprima se la richiesta è scaduta.");
        var selezione = Elementi.Where(x => x.Selezionato).ToArray();
        if (Elementi.Count > 500 || selezione.Length == 0)
            ModelState.AddModelError(string.Empty, "Selezionare da 1 a 500 elementi da ordinare.");
        if (selezione.Select(x => (x.Tipo, x.IdOrigine)).Distinct().Count() != selezione.Length)
            ModelState.AddModelError(string.Empty, "La selezione contiene elementi duplicati. Riaprire l’anteprima.");
        foreach (var elemento in selezione)
        {
            // L'appartenenza e il residuo sono ripetuti nella transazione SQL.
            // Il controllo qui conserva i dati digitati e offre un errore immediato.
            if (Origini.All(s => s.Tipo != elemento.Tipo || s.IdOrigine != elemento.IdOrigine))
                ModelState.AddModelError(string.Empty, "Un elemento selezionato non è più disponibile. Riaprire l’anteprima.");
            if (!Fornitori.Any(f => f.IdFornitore == elemento.IdFornitore))
                ModelState.AddModelError(string.Empty, "Assegnare un fornitore attivo a ogni elemento selezionato.");
            if (elemento.Quantita <= 0 || elemento.PrezzoUnitario < 0
                || elemento.Quantita >= 100000000000000m || elemento.PrezzoUnitario >= 100000000000000m
                || decimal.Round(elemento.Quantita, 4) != elemento.Quantita || decimal.Round(elemento.PrezzoUnitario, 4) != elemento.PrezzoUnitario)
                ModelState.AddModelError(string.Empty, "Usare quantità positive e prezzi non negativi, con al massimo quattro decimali.");
        }
        if (!ModelState.IsValid) return Page();
        try
        {
            Creati = await repository.ConfermaAsync(IdPreventivo, IdRigaPreventivo, Richiesta, DataOrdine,
                selezione.Select(x => new AcquistoSelezionato(x.Tipo, x.IdOrigine, x.Impronta,
                    x.IdFornitore!.Value, x.Quantita, x.PrezzoUnitario)).ToArray(), User.Identity?.Name ?? "Sistema", cancellationToken);
            return Page();
        }
        catch (SqlException exception) when (OrdiniFornitoriErrori.Gestito(exception.Number) || exception.Number == 1205)
        {
            logger.LogWarning(exception, "Generazione acquisti preventivo {IdPreventivo} rifiutata", IdPreventivo);
            ModelState.AddModelError(string.Empty, exception.Number == 1205
                ? "Operazione concorrente. Riprovare la conferma." : OrdiniFornitoriErrori.Messaggio(exception.Number));
            await CaricaAsync(cancellationToken);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(CancellationToken cancellationToken)
    {
        Preventivo = await preventivi.GetDettaglioAsync(IdPreventivo, cancellationToken);
        if (Preventivo is null) return false;
        if (IdRigaPreventivo.HasValue && (await preventivi.GetRigaAsync(IdRigaPreventivo.Value, cancellationToken))?.IdPreventivo != IdPreventivo)
            return false;
        Origini = await repository.GetAnteprimaAsync(IdPreventivo, IdRigaPreventivo, cancellationToken);
        Fornitori = await fornitori.GetElencoAsync(soloAttivi: true, cancellationToken: cancellationToken);
        return true;
    }

    public sealed class AcquistoForm
    {
        public bool Selezionato { get; set; }
        public string Tipo { get; set; } = string.Empty;
        public int IdOrigine { get; set; }
        public string Impronta { get; set; } = string.Empty;
        public int? IdFornitore { get; set; }
        public decimal Quantita { get; set; }
        public decimal PrezzoUnitario { get; set; }
    }
}

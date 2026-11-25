using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public sealed class ApplicaMarkupModel(IPreventivoRepository repository, ILogger<ApplicaMarkupModel> logger) : PageModel
{
    public PreventivoDettaglio? Preventivo { get; private set; }
    public IReadOnlyList<PreventivoMarkupAnteprima> Righe { get; private set; } = [];
    public bool Modificabile => PreventivoMarkupAnteprima.StatoModificabile(Righe.FirstOrDefault()?.Stato ?? string.Empty);
    [BindProperty, Range(typeof(decimal), "0", "9999999.99", ParseLimitsInInvariantCulture = true,
        ErrorMessage = "Inserire una percentuale compresa tra 0 e 9.999.999,99.")]
    public decimal Markup { get; set; }
    [BindProperty] public string Impronta { get; set; } = string.Empty;
    [BindProperty] public bool Conferma { get; set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Markup = Righe[0].MarkupPercDefault;
        Impronta = Righe[0].Impronta;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        if (!Modificabile)
            ModelState.AddModelError(string.Empty, "Lo stato del preventivo non consente l’applicazione del markup.");
        if (!Conferma)
            ModelState.AddModelError(nameof(Conferma), "Confermare l’applicazione alle righe esistenti.");
        if (Markup < 0 || Markup > 9999999.99m || decimal.Round(Markup, 2) != Markup)
            ModelState.AddModelError(nameof(Markup), "Inserire un markup non negativo con al massimo due decimali.");
        if (string.IsNullOrEmpty(Impronta) || !string.Equals(Impronta, Righe[0].Impronta, StringComparison.Ordinal))
            ModelState.AddModelError(string.Empty, "Il preventivo è cambiato. Riaprire la pagina e verificare i dati prima di confermare.");
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.ApplicaMarkupAsync(id, Markup, Impronta, cancellationToken);
            logger.LogInformation("Markup {Markup} applicato al preventivo {IdPreventivo} da {Utente}", Markup, id, User.Identity?.Name);
            TempData["MessaggioSuccesso"] = "Markup applicato alle righe con prezzo automatico. Prezzi manuali conservati e totali ricalcolati.";
            return RedirectToPage("/Preventivi/Dettaglio", new { id });
        }
        catch (SqlException exception) when (exception.Number is >= 54201 and <= 54204 or >= 51924 and <= 51928 or 8115 or 1205)
        {
            logger.LogWarning(exception, "Applicazione markup al preventivo {IdPreventivo} rifiutata", id);
            ModelState.AddModelError(string.Empty, exception.Number switch
            {
                54201 => "Il preventivo non è più disponibile.",
                54202 => "Lo stato del preventivo non consente l’applicazione del markup.",
                54203 => "Il preventivo è cambiato. Riaprire la pagina prima di confermare.",
                54204 => "La percentuale di markup non è valida.",
                8115 => "Il markup produce importi superiori ai limiti consentiti. Ridurre la percentuale.",
                1205 => "Un’altra operazione ha modificato i dati. Riaprire la pagina e riprovare.",
                _ => "Il ricalcolo richiede la verifica dei dati delle righe e delle varianti. Nessuna modifica è stata applicata."
            });
            await CaricaAsync(id, cancellationToken);
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        Preventivo = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Preventivo is null) return false;
        Righe = await repository.GetAnteprimaMarkupAsync(id, cancellationToken);
        return Righe.Count > 0;
    }
}

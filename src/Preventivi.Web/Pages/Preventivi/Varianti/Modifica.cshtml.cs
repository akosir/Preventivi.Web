using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Varianti;

public sealed class ModificaModel(IPreventivoRepository repository, ILogger<ModificaModel> logger) : PageModel
{
    [BindProperty(SupportsGet = true)] public int IdPreventivo { get; set; }
    [BindProperty(SupportsGet = true)] public int IdVariantePreventivo { get; set; }
    [BindProperty, Required(ErrorMessage = "Inserire il codice variante."), StringLength(30, ErrorMessage = "Il codice variante puo contenere al massimo {1} caratteri.")]
    public string Codice { get; set; } = string.Empty;
    [BindProperty, Required(ErrorMessage = "Inserire la descrizione variante."), StringLength(250, ErrorMessage = "La descrizione variante puo contenere al massimo {1} caratteri.")]
    public string Descrizione { get; set; } = string.Empty;
    [BindProperty] public string? Note { get; set; }
    [BindProperty] public bool VarianteScelta { get; set; }
    [BindProperty] public string Impronta { get; set; } = string.Empty;
    public PreventivoVarianteItem? Variante { get; private set; }
    public PreventivoDettaglio? Preventivo { get; private set; }
    public bool Modificabile => Variante?.Attiva == true && PreventivoMarkupAnteprima.StatoModificabile(Preventivo?.Stato ?? "");

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(cancellationToken)) return NotFound();
        Codice = Variante!.CodiceVariante;
        Descrizione = Variante.DescrizioneVariante;
        Note = Variante.Note;
        VarianteScelta = Variante.VarianteScelta;
        Impronta = Variante.Impronta;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(cancellationToken)) return NotFound();
        if (!Modificabile) ModelState.AddModelError(string.Empty, "Lo stato del preventivo o della variante non consente modifiche.");
        if (string.IsNullOrWhiteSpace(Codice) || Codice.Length > 30)
            ModelState.AddModelError(nameof(Codice), "Inserire un codice variante di massimo 30 caratteri.");
        if (string.IsNullOrWhiteSpace(Descrizione) || Descrizione.Length > 250)
            ModelState.AddModelError(nameof(Descrizione), "Inserire una descrizione di massimo 250 caratteri.");
        if (string.IsNullOrEmpty(Impronta) || Impronta != Variante!.Impronta)
            ModelState.AddModelError(string.Empty, "La variante è cambiata. Riaprire la pagina prima di salvare.");
        if (!ModelState.IsValid) return Page();
        try
        {
            await repository.AggiornaVarianteAsync(IdPreventivo, IdVariantePreventivo, Codice, Descrizione, Note, Impronta, VarianteScelta, cancellationToken);
            TempData["MessaggioSuccesso"] = "Variante aggiornata, scelta salvata e totali del preventivo ricalcolati.";
            return RedirectToPage("./Dettaglio", new { IdPreventivo, IdVariantePreventivo });
        }
        catch (SqlException exception) when (exception.Number is >= 54211 and <= 54215 or >= 51924 and <= 51926 or 51953 or 2601 or 2627 or 1205 or 8115)
        {
            logger.LogWarning(exception, "Modifica variante {IdVariante} del preventivo {IdPreventivo} rifiutata", IdVariantePreventivo, IdPreventivo);
            ModelState.AddModelError(string.Empty, exception.Number switch
            {
                54211 => "La variante non appartiene al preventivo indicato.",
                54212 => "Lo stato del preventivo o della variante non consente modifiche.",
                54213 or 1205 => "La variante è cambiata. Riaprire la pagina prima di salvare.",
                54215 or 2601 or 2627 => "Il codice variante è già utilizzato nel preventivo.",
                51924 or 51925 or 51926 or 51953 or 8115 => "Il ricalcolo della scelta richiede la verifica di righe e varianti. Nessuna modifica è stata applicata.",
                _ => "Verificare codice e descrizione della variante."
            });
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(CancellationToken cancellationToken)
    {
        if (IdPreventivo <= 0 || IdVariantePreventivo <= 0) return false;
        Variante = await repository.GetVarianteAsync(IdVariantePreventivo, cancellationToken);
        if (Variante is null || Variante.IdPreventivo != IdPreventivo) return false;
        Preventivo = await repository.GetDettaglioAsync(IdPreventivo, cancellationToken);
        return Preventivo is not null;
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli.Righe;

public sealed class NuovaModel : ModelloPreventivoRigaPageBase
{
    public NuovaModel(
        IModelloPreventivoRepository modelloRepository,
        IPreventivoRepository preventivoRepository)
        : base(modelloRepository, preventivoRepository)
    {
    }

    [BindProperty(SupportsGet = true)]
    public int IdModello { get; set; }

    [BindProperty]
    public ModelloPreventivoRigaFormModel Dati { get; set; } = new();

    public ModelloPreventivoRigaFormViewModel Form => CreaForm(Dati);

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaModelloAsync(IdModello, cancellationToken))
            return NotFound();

        await CaricaLookupAsync(cancellationToken);
        var righe = await ModelloRepository.GetRigheAsync(IdModello, cancellationToken);
        Dati.RigaNr = righe.Count == 0 ? 1 : righe.Max(riga => riga.RigaNr) + 1;
        Dati.IdTipoRiga = TipiRiga.FirstOrDefault()?.IdTipoRiga ?? 0;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaModelloAsync(IdModello, cancellationToken))
            return NotFound();

        await CaricaLookupAsync(cancellationToken);
        ValidaRiga(Dati, ModelState);
        if (!ModelState.IsValid)
            return Page();

        try
        {
            await ModelloRepository.CreaRigaAsync(
                new ModelloPreventivoRigaCreateModel
                {
                    IdModelloPreventivo = IdModello,
                    RigaNr = Dati.RigaNr,
                    IdTipoRiga = Dati.IdTipoRiga,
                    IdArticolo = Dati.IdArticolo,
                    IdModelloCiclo = Dati.IdModelloCiclo,
                    DescrizioneVoce = Dati.DescrizioneVoce,
                    Quantita = Dati.Quantita,
                    PrezzoUnitarioVendita = Dati.PrezzoUnitarioVendita,
                    Note = Dati.Note
                },
                cancellationToken);
        }
        catch (SqlException exception) when (ErroreRigaPrevisto(exception.Number))
        {
            ModelState.AddModelError(
                string.Empty,
                exception.Number is 2601 or 2627
                    ? "Il numero riga e gia utilizzato nel modello."
                    : exception.Message);
            return Page();
        }

        TempData["MessaggioSuccesso"] = "Riga modello creata correttamente.";
        return RedirectToPage("../Dettaglio", new { id = IdModello });
    }
}

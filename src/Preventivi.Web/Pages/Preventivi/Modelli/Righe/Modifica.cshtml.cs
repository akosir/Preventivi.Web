using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli.Righe;

public sealed class ModificaModel : ModelloPreventivoRigaPageBase
{
    public ModificaModel(
        IModelloPreventivoRepository modelloRepository,
        IPreventivoRepository preventivoRepository)
        : base(modelloRepository, preventivoRepository)
    {
    }

    [BindProperty(SupportsGet = true)]
    public int IdModello { get; set; }

    [BindProperty(SupportsGet = true)]
    public int IdRiga { get; set; }

    [BindProperty]
    public ModelloPreventivoRigaFormModel Dati { get; set; } = new();

    public ModelloPreventivoRigaItem? Riga { get; private set; }

    public ModelloPreventivoRigaFormViewModel Form => CreaForm(Dati);

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(cancellationToken))
            return NotFound();

        await CaricaLookupAsync(cancellationToken);
        Dati = new ModelloPreventivoRigaFormModel
        {
            RigaNr = Riga!.RigaNr,
            IdTipoRiga = Riga.IdTipoRiga,
            IdArticolo = Riga.IdArticolo,
            IdModelloCiclo = Riga.IdModelloCiclo,
            DescrizioneVoce = Riga.DescrizioneVoce,
            Quantita = Riga.Quantita,
            PrezzoUnitarioVendita = Riga.PrezzoUnitarioVendita,
            Note = Riga.Note
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(cancellationToken))
            return NotFound();

        await CaricaLookupAsync(cancellationToken);
        ValidaRiga(Dati, ModelState);
        if (!ModelState.IsValid)
            return Page();

        try
        {
            await ModelloRepository.AggiornaRigaAsync(
                new ModelloPreventivoRigaUpdateModel
                {
                    IdRigaModelloPreventivo = IdRiga,
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

        TempData["MessaggioSuccesso"] = "Riga modello aggiornata correttamente.";
        return RedirectToPage("../Dettaglio", new { id = IdModello });
    }

    private async Task<bool> CaricaContestoAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaModelloAsync(IdModello, cancellationToken))
            return false;

        Riga = await ModelloRepository.GetRigaAsync(IdRiga, cancellationToken);
        return Riga?.IdModelloPreventivo == IdModello;
    }
}

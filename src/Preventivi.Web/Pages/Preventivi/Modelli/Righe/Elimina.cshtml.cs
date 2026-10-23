using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli.Righe;

public sealed class EliminaModel : ModelloPreventivoRigaPageBase
{
    public EliminaModel(
        IModelloPreventivoRepository modelloRepository,
        IPreventivoRepository preventivoRepository)
        : base(modelloRepository, preventivoRepository)
    {
    }

    [BindProperty(SupportsGet = true)]
    public int IdModello { get; set; }

    [BindProperty(SupportsGet = true)]
    public int IdRiga { get; set; }

    public ModelloPreventivoRigaItem? Riga { get; private set; }

    public async Task<IActionResult> OnGetAsync(CancellationToken cancellationToken)
    {
        return await CaricaContestoAsync(cancellationToken) ? Page() : NotFound();
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!await CaricaContestoAsync(cancellationToken))
            return NotFound();

        try
        {
            await ModelloRepository.EliminaRigaAsync(IdRiga, cancellationToken);
        }
        catch (SqlException exception) when (exception.Number == 52129)
        {
            return NotFound();
        }

        TempData["MessaggioSuccesso"] = "Riga modello eliminata correttamente.";
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

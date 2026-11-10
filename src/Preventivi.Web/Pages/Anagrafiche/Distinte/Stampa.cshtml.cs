using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Distinte;

public sealed class StampaModel : PageModel
{
    private readonly IDistintaBaseReportService _report;

    public StampaModel(IDistintaBaseReportService report)
    {
        _report = report;
    }

    public async Task<IActionResult> OnGetAsync(
        int idArticolo,
        CancellationToken cancellationToken)
    {
        var risultato = await _report.GeneraPdfAsync(
            idArticolo,
            cancellationToken);
        if (risultato is null)
        {
            return NotFound();
        }

        return File(
            risultato.Contenuto,
            "application/pdf",
            risultato.NomeFile);
    }
}

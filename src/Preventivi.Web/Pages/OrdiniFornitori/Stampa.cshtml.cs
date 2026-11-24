using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.OrdiniFornitori;
using System.Text.Json;

namespace Preventivi.Web.Pages.OrdiniFornitori;

public sealed class StampaModel(IOrdineFornitoreRepository repository) : PageModel
{
    public OrdineFornitoreDettaglio? Ordine { get; private set; }
    public IReadOnlyList<OrdineFornitoreRiga> Righe { get; private set; } = [];
    public OrdineFornitoreDocumento? Documento { get; private set; }
    public bool CopiaStoricaAssente { get; private set; }
    public async Task<IActionResult> OnGetAsync(int id, int? idDocumento, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid) return BadRequest();
        Ordine = await repository.GetDettaglioAsync(id, cancellationToken);
        if (Ordine is null) return NotFound();
        if (idDocumento.HasValue || !Ordine.Modificabile)
        {
            var copia = await repository.GetDocumentoAsync(id, idDocumento, cancellationToken);
            if (copia is not null)
            {
                Documento = copia;
                Ordine = JsonSerializer.Deserialize<OrdineFornitoreDettaglio>(copia.TestataJson)
                    ?? throw new InvalidOperationException("La testata del documento storico non è valida.");
                Righe = JsonSerializer.Deserialize<OrdineFornitoreRiga[]>(copia.RigheJson)
                    ?? throw new InvalidOperationException("Le righe del documento storico non sono valide.");
                return Page();
            }
            if (idDocumento.HasValue) return NotFound();
            CopiaStoricaAssente = true;
        }
        Righe = await repository.GetRigheAsync(id, cancellationToken);
        return Page();
    }
}

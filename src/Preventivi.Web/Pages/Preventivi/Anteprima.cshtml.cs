using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class AnteprimaModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public PreventivoDettaglio? Preventivo { get; private set; }

    public IReadOnlyList<RigaAnteprima> Righe { get; private set; }
        = Array.Empty<RigaAnteprima>();

    public bool UsoInterno { get; private set; }

    public string TipoAnteprima => UsoInterno ? "interna" : "cliente";

    public AnteprimaModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public async Task<IActionResult> OnGetAsync(
        int id,
        string tipo,
        CancellationToken cancellationToken)
    {
        if (!string.Equals(tipo, "cliente", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(tipo, "interna", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest();
        }

        UsoInterno = string.Equals(tipo, "interna", StringComparison.OrdinalIgnoreCase);
        Preventivo = await _repository.GetDettaglioAsync(id, cancellationToken);

        if (Preventivo is null)
        {
            return NotFound();
        }

        var righe = await _repository.GetRigheAsync(id, cancellationToken);

        if (!UsoInterno)
        {
            Righe = righe.Select(riga => new RigaAnteprima(riga)).ToArray();
            return Page();
        }

        var righeAnteprima = new List<RigaAnteprima>(righe.Count);

        foreach (var riga in righe)
        {
            var rigaAnteprima = new RigaAnteprima(riga)
            {
                MaterialiComuni = await _repository.GetMaterialiAsync(
                    riga.IdRigaPreventivo,
                    null,
                    cancellationToken),
                LavorazioniComuni = await _repository.GetLavorazioniAsync(
                    riga.IdRigaPreventivo,
                    null,
                    cancellationToken)
            };

            var componenti = await _repository.GetComponentiAsync(
                riga.IdRigaPreventivo,
                cancellationToken);

            var componentiAnteprima = new List<ComponenteAnteprima>(componenti.Count);

            foreach (var componente in componenti)
            {
                componentiAnteprima.Add(new ComponenteAnteprima(
                    componente,
                    await _repository.GetMaterialiAsync(
                        riga.IdRigaPreventivo,
                        componente.IdRigaCompPrev,
                        cancellationToken),
                    await _repository.GetLavorazioniAsync(
                        riga.IdRigaPreventivo,
                        componente.IdRigaCompPrev,
                        cancellationToken)));
            }

            rigaAnteprima.Componenti = componentiAnteprima;
            righeAnteprima.Add(rigaAnteprima);
        }

        Righe = righeAnteprima;
        return Page();
    }

    public sealed class RigaAnteprima
    {
        public PreventivoRigaListItem Riga { get; }

        public IReadOnlyList<PreventivoRigaMaterialeItem> MaterialiComuni { get; set; }
            = Array.Empty<PreventivoRigaMaterialeItem>();

        public IReadOnlyList<PreventivoRigaLavorazioneItem> LavorazioniComuni { get; set; }
            = Array.Empty<PreventivoRigaLavorazioneItem>();

        public IReadOnlyList<ComponenteAnteprima> Componenti { get; set; }
            = Array.Empty<ComponenteAnteprima>();

        public RigaAnteprima(PreventivoRigaListItem riga)
        {
            Riga = riga;
        }
    }

    public sealed record ComponenteAnteprima(
        PreventivoRigaComponenteItem Componente,
        IReadOnlyList<PreventivoRigaMaterialeItem> Materiali,
        IReadOnlyList<PreventivoRigaLavorazioneItem> Lavorazioni);
}

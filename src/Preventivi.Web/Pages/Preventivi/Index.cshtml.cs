using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;

namespace Preventivi.Web.Pages.Preventivi;

public class IndexModel : PageModel
{
    private readonly IPreventivoRepository _repository;

    public IReadOnlyList<PreventivoListItem> Preventivi { get; private set; }
        = Array.Empty<PreventivoListItem>();

    public IReadOnlyList<string> Stati { get; private set; }
        = Array.Empty<string>();

    public IReadOnlyList<int> Anni { get; private set; }
        = Array.Empty<int>();

    [BindProperty(SupportsGet = true)]
    public string? Ricerca { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? Stato { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? Anno { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? DataDa { get; set; }

    [BindProperty(SupportsGet = true)]
    public DateOnly? DataA { get; set; }

    public bool HaFiltri =>
        !string.IsNullOrWhiteSpace(Ricerca) ||
        !string.IsNullOrWhiteSpace(Stato) ||
        Anno.HasValue ||
        DataDa.HasValue ||
        DataA.HasValue;

    public IndexModel(IPreventivoRepository repository)
    {
        _repository = repository;
    }

    public async Task OnGetAsync(
        CancellationToken cancellationToken)
    {
        var preventivi = await _repository.GetElencoAsync(cancellationToken);

        Stati = preventivi
            .Select(preventivo => preventivo.Stato)
            .Where(stato => !string.IsNullOrWhiteSpace(stato))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(stato => stato, StringComparer.CurrentCultureIgnoreCase)
            .ToArray();

        Anni = preventivi
            .Select(preventivo => preventivo.Anno)
            .Distinct()
            .OrderByDescending(anno => anno)
            .ToArray();

        IEnumerable<PreventivoListItem> risultati = preventivi;

        if (!string.IsNullOrWhiteSpace(Ricerca))
        {
            var testo = Ricerca.Trim();
            risultati = risultati.Where(preventivo =>
                preventivo.NumeroCompleto.Contains(testo, StringComparison.OrdinalIgnoreCase) ||
                preventivo.Cliente.Contains(testo, StringComparison.CurrentCultureIgnoreCase) ||
                preventivo.Oggetto.Contains(testo, StringComparison.CurrentCultureIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(Stato))
        {
            risultati = risultati.Where(preventivo =>
                string.Equals(preventivo.Stato, Stato, StringComparison.OrdinalIgnoreCase));
        }

        if (Anno.HasValue)
        {
            risultati = risultati.Where(preventivo => preventivo.Anno == Anno.Value);
        }

        if (DataDa.HasValue)
        {
            risultati = risultati.Where(preventivo => preventivo.DataPreventivo >= DataDa.Value);
        }

        if (DataA.HasValue)
        {
            risultati = risultati.Where(preventivo => preventivo.DataPreventivo <= DataA.Value);
        }

        Preventivi = risultati.ToArray();
    }
}

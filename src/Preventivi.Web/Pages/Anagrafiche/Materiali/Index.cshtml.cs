using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Materiali;

public sealed class IndexModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;

    public IndexModel(IAnagraficheProduttiveRepository repository)
    {
        _repository = repository;
    }

    [BindProperty(SupportsGet = true)] public string? Ricerca { get; set; }
    [BindProperty(SupportsGet = true)] public string Stato { get; set; } = "attivi";
    [BindProperty(SupportsGet = true)] public string? TipoMateriale { get; set; }
    public IReadOnlyList<MaterialeListItem> Materiali { get; private set; } = [];

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        bool? soloAttivi = Stato switch
        {
            "attivi" => true,
            "nonattivi" => false,
            _ => null
        };
        Materiali = await _repository.GetMaterialiAsync(
            Ricerca,
            soloAttivi,
            TipoMateriale,
            cancellationToken);
    }

    public static string EtichettaTipo(string tipo) => tipo switch
    {
        "MateriaPrima" => "Materia prima",
        _ => tipo
    };
}

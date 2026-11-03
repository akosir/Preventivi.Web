using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Web.UI.Modules.Anagrafiche;

namespace Preventivi.Web.Pages.Anagrafiche.Materiali;

public sealed class ModificaModel : PageModel
{
    private readonly IAnagraficheProduttiveRepository _repository;
    private readonly ILogger<ModificaModel> _logger;

    public ModificaModel(IAnagraficheProduttiveRepository repository, ILogger<ModificaModel> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    [BindProperty] public MaterialeFormModel Dati { get; set; } = new();
    public int IdMateriale { get; private set; }
    private MaterialeDettaglio? Corrente { get; set; }

    public async Task<IActionResult> OnGetAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Dati = new MaterialeFormModel
        {
            CodiceMateriale = Corrente!.CodiceMateriale,
            Descrizione = Corrente.Descrizione,
            IdUM = Corrente.IdUM,
            TipoMateriale = Corrente.TipoMateriale,
            CostoUnitario = Corrente.CostoUnitario,
            GestitoAAcquisto = Corrente.GestitoAAcquisto,
            IdFornitorePredefinito = Corrente.IdFornitorePredefinito,
            Note = Corrente.Note,
            VersioneRigaBase64 = Convert.ToBase64String(Corrente.VersioneRiga)
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id, CancellationToken cancellationToken)
    {
        if (!await CaricaAsync(id, cancellationToken)) return NotFound();
        Valida();
        var versione = LeggiVersione();
        if (!ModelState.IsValid) return Page();

        try
        {
            await _repository.AggiornaMaterialeAsync(new MaterialeUpdateModel
            {
                IdMateriale = id,
                CodiceMateriale = Dati.CodiceMateriale,
                Descrizione = Dati.Descrizione,
                IdUM = Dati.IdUM.GetValueOrDefault(),
                TipoMateriale = Dati.TipoMateriale,
                CostoUnitario = Dati.CostoUnitario,
                GestitoAAcquisto = Dati.GestitoAAcquisto,
                IdFornitorePredefinito = Dati.IdFornitorePredefinito,
                Note = Dati.Note,
                Utente = User.Identity?.Name ?? "Sistema",
                VersioneRiga = versione
            }, cancellationToken);
            TempData["MessaggioSuccesso"] = "Materiale aggiornato correttamente.";
            return RedirectToPage("./Dettaglio", new { id });
        }
        catch (SqlException exception) when (AnagraficheProduttiveSqlErrori.Gestito(exception.Number))
        {
            _logger.LogWarning(exception, "Aggiornamento materiale {Id} rifiutato", id);
            ModelState.AddModelError(string.Empty, AnagraficheProduttiveSqlErrori.Messaggio(exception.Number));
            return Page();
        }
    }

    private async Task<bool> CaricaAsync(int id, CancellationToken cancellationToken)
    {
        if (id <= 0) return false;
        IdMateriale = id;
        Corrente = await _repository.GetMaterialeAsync(id, cancellationToken);
        if (Corrente is null) return false;
        ViewData["UnitaMisura"] = await _repository.GetUnitaMisuraAsync(Corrente.IdUM, cancellationToken);
        ViewData["Fornitori"] = await _repository.GetFornitoriAsync(Corrente.IdFornitorePredefinito, cancellationToken);
        return true;
    }

    private void Valida()
    {
        if (!new[] { "MateriaPrima", "Accessorio", "Semilavorato" }.Contains(Dati.TipoMateriale))
            ModelState.AddModelError("Dati.TipoMateriale", "Selezionare un tipo materiale valido.");
        if (!Dati.GestitoAAcquisto && Dati.IdFornitorePredefinito.HasValue)
            ModelState.AddModelError("Dati.IdFornitorePredefinito", "Il fornitore e ammesso soltanto per materiali gestiti ad acquisto.");
    }

    private byte[] LeggiVersione()
    {
        try { return Convert.FromBase64String(Dati.VersioneRigaBase64 ?? string.Empty); }
        catch (FormatException)
        {
            ModelState.AddModelError(string.Empty, "La versione dei dati non e valida. Ricaricare la pagina.");
            return [];
        }
    }
}

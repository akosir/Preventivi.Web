using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using IAnagraficheProduttiveRepository = Preventivi.Core.Anagrafiche.IAnagraficheProduttiveRepository;
using Preventivi.Core.Preventivi;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class MaterialiModel : PageModel
{
    public const string OrigineDistinta = "Distinta";
    public const string OrigineAnagrafica = "Anagrafica";
    public const string OrigineLibero = "Libero";

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IAnagraficheProduttiveRepository _anagraficheRepository;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IPreventivoEliminazioneService _eliminazioneService;

    public PreventivoRigaMaterialeItem? Materiale { get; private set; }

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    public AllegatiGridModel Allegati { get; private set; } = new();

    public IReadOnlyList<DistintaMaterialeLookupItem> MaterialiDistinta { get; private set; }
        = Array.Empty<DistintaMaterialeLookupItem>();

    public IReadOnlyList<MaterialeLookupItem> MaterialiAnagrafica { get; private set; }
        = Array.Empty<MaterialeLookupItem>();

    public IReadOnlyList<FornitoreLookupItem> Fornitori { get; private set; }
        = Array.Empty<FornitoreLookupItem>();

    public DistintaMaterialeLookupItem? MaterialeDistintaSelezionato { get; private set; }

    public MaterialeLookupItem? MaterialeAnagraficaSelezionato { get; private set; }

    [BindProperty(SupportsGet = true)]
    public string Origine { get; set; } = OrigineLibero;

    [BindProperty(SupportsGet = true)]
    public string? RicercaMateriale { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdDistintaMaterialeSelezionato { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdMaterialeSelezionato { get; set; }

    [BindProperty]
    public PreventivoRigaMaterialeCreateModel NuovoMateriale { get; set; } = new();

    public MaterialiModel(
        IPreventivoRepository preventivoRepository,
        IAllegatoRepository allegatoRepository,
        IPreventivoEliminazioneService eliminazioneService,
        IAnagraficheProduttiveRepository anagraficheRepository)
    {
        _preventivoRepository = preventivoRepository;
        _allegatoRepository = allegatoRepository;
        _eliminazioneService = eliminazioneService;
        _anagraficheRepository = anagraficheRepository;
    }

    public async Task<IActionResult> OnGetAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, idComponente, id))
        {
            return BadRequest();
        }

        if (!await RigaAppartieneAlPreventivoAsync(
                idPreventivo,
                idRigaPreventivo,
                cancellationToken))
        {
            return NotFound();
        }

        Componente =
            await _preventivoRepository.GetComponenteAsync(
                idComponente,
                cancellationToken);

        if (Componente is null ||
            Componente.IdRigaPreventivo != idRigaPreventivo)
        {
            return NotFound();
        }

        if (IsNuovo(modo))
        {
            await PreparaNuovoMaterialeAsync(
                idRigaPreventivo,
                cancellationToken);

            return Page();
        }

        Materiale =
            await _preventivoRepository.GetMaterialeAsync(
                id!.Value,
                cancellationToken);

        if (Materiale is null ||
            Materiale.IdRigaPreventivo != idRigaPreventivo ||
            Materiale.IdRigaCompPrev != Componente.IdRigaCompPrev)
        {
            return NotFound();
        }

        if (IsDettaglio(modo))
        {
            Allegati = new AllegatiGridModel
            {
                Allegati =
                    await _allegatoRepository.GetElencoAsync(
                        "PreventiviRigheMateriali",
                        Materiale.IdRigaMatPrev,
                        cancellationToken),
                ReturnUrl = GetMaterialeReturnUrl(
                    idPreventivo,
                    idRigaPreventivo,
                    idComponente,
                    Materiale.IdRigaMatPrev)
            };
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, idComponente, id))
        {
            return BadRequest();
        }

        if (!await RigaAppartieneAlPreventivoAsync(
                idPreventivo,
                idRigaPreventivo,
                cancellationToken))
        {
            return NotFound();
        }

        Componente =
            await _preventivoRepository.GetComponenteAsync(
                idComponente,
                cancellationToken);

        if (Componente is null ||
            Componente.IdRigaPreventivo != idRigaPreventivo)
        {
            return NotFound();
        }

        if (IsElimina(modo))
        {
            var materiale =
                await _preventivoRepository.GetMaterialeAsync(
                    id!.Value,
                    cancellationToken);

            if (materiale is null ||
                materiale.IdRigaPreventivo != idRigaPreventivo ||
                materiale.IdRigaCompPrev != Componente.IdRigaCompPrev)
            {
                return NotFound();
            }

            try
            {
                await _eliminazioneService.EliminaAsync(
                    TipoEliminazionePreventivo.Materiale,
                    id.Value,
                    cancellationToken);
            }
            catch (PreventivoEliminazioneException exception)
            {
                if (exception.EliminazioneCompletata)
                {
                    return RedirectToComponente(idPreventivo, idRigaPreventivo, idComponente);
                }

                ModelState.AddModelError(string.Empty, exception.Message);
                Materiale = materiale;
                return Page();
            }

            return RedirectToComponente(idPreventivo, idRigaPreventivo, idComponente);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        await PreparaNuovoMaterialeAsync(
            idRigaPreventivo,
            cancellationToken,
            inizializza: false);

        if (Origine == OrigineDistinta)
        {
            if (IdDistintaMaterialeSelezionato is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdDistintaMaterialeSelezionato),
                    "Selezionare un materiale della distinta.");
            }
            else if (MaterialeDistintaSelezionato is null)
            {
                ModelState.AddModelError(
                    nameof(IdDistintaMaterialeSelezionato),
                    "Materiale distinta non trovato.");
            }
            else
            {
                ApplicaMaterialeDistinta(MaterialeDistintaSelezionato, inizializza: false);
            }
        }

        if (Origine == OrigineAnagrafica)
        {
            if (IdMaterialeSelezionato is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdMaterialeSelezionato),
                    "Selezionare un materiale.");
            }
            else if (MaterialeAnagraficaSelezionato is null)
            {
                ModelState.AddModelError(
                    nameof(IdMaterialeSelezionato),
                    "Materiale non trovato.");
            }
            else
            {
                ApplicaMaterialeAnagrafica(MaterialeAnagraficaSelezionato, inizializza: false);
            }
        }

        NuovoMateriale.IdRigaPreventivo = idRigaPreventivo;
        NuovoMateriale.IdRigaCompPrev = Componente.IdRigaCompPrev;
        NuovoMateriale.IdNodoDistinta = Componente.IdNodoDistinta;

        if (Origine == OrigineLibero)
            NuovoMateriale.IdMateriale = null;
        else
        {
            foreach (var campo in new[] { "IdMateriale", "DescrizioneMateriale", "TipoMateriale", "UM" })
                ModelState.Remove($"NuovoMateriale.{campo}");
        }

        if (string.IsNullOrWhiteSpace(NuovoMateriale.DescrizioneMateriale))
            ModelState.AddModelError("NuovoMateriale.DescrizioneMateriale", "La descrizione del materiale e obbligatoria.");
        if (NuovoMateriale.Quantita < 0 || NuovoMateriale.CostoUnitario < 0)
            ModelState.AddModelError(string.Empty, "Quantita e costo non possono essere negativi.");
        if (NuovoMateriale.IdFornitoreSuggerito.HasValue &&
            Fornitori.All(x => x.IdFornitore != NuovoMateriale.IdFornitoreSuggerito))
            ModelState.AddModelError("NuovoMateriale.IdFornitoreSuggerito", "Selezionare un fornitore attivo disponibile.");

        global::Preventivi.Web.UI.ValidazioneLunghezzeTesto.ValidaLunghezzeTesto(ModelState, NuovoMateriale, "NuovoMateriale");
        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idMateriale =
            await _preventivoRepository.CreaMaterialeAsync(
                NuovoMateriale,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Materiali",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                idComponente,
                id = idMateriale
            });
    }

    public IActionResult RedirectToComponente(
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente)
    {
        return RedirectToPage(
            "/Preventivi/Riga/Componenti",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                id = idComponente
            });
    }

    private async Task PreparaNuovoMaterialeAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken,
        bool inizializza = true)
    {
        if (!inizializza && !new[] { OrigineDistinta, OrigineAnagrafica, OrigineLibero }
                .Contains(Origine, StringComparer.OrdinalIgnoreCase))
            ModelState.AddModelError(nameof(Origine), "Selezionare un'origine materiale valida.");
        NormalizeOrigine();

        if (Componente?.IdNodoDistinta is > 0)
        {
            MaterialiDistinta =
                await _preventivoRepository.GetMaterialiDistintaAsync(
                    Componente.IdNodoDistinta.Value,
                    cancellationToken);
        }

        MaterialiAnagrafica =
            await _preventivoRepository.CercaMaterialiAsync(
                RicercaMateriale,
                cancellationToken);

        Fornitori =
            await _preventivoRepository.GetFornitoriAsync(cancellationToken);

        var materialiAttivi = await _anagraficheRepository.GetMaterialiAsync(
            soloAttivi: true, cancellationToken: cancellationToken);
        var idAttivi = materialiAttivi.Select(x => x.IdMateriale).ToHashSet();
        MaterialiDistinta = MaterialiDistinta.Where(x => idAttivi.Contains(x.IdMateriale)).ToArray();
        MaterialiAnagrafica = MaterialiAnagrafica.Where(x => idAttivi.Contains(x.IdMateriale)).ToArray();

        if (Origine == OrigineDistinta && IdDistintaMaterialeSelezionato is > 0)
        {
            MaterialeDistintaSelezionato =
                MaterialiDistinta.FirstOrDefault(x =>
                    x.IdDistintaMateriale == IdDistintaMaterialeSelezionato &&
                    x.IdNodoDistinta == Componente?.IdNodoDistinta);

            if (inizializza && MaterialeDistintaSelezionato is not null)
            {
                ApplicaMaterialeDistinta(MaterialeDistintaSelezionato);
            }
        }

        if (Origine == OrigineAnagrafica && IdMaterialeSelezionato is > 0 &&
            idAttivi.Contains(IdMaterialeSelezionato.Value))
        {
            MaterialeAnagraficaSelezionato =
                await _preventivoRepository.GetMaterialeAnagraficaAsync(
                    IdMaterialeSelezionato.Value,
                    cancellationToken);

            if (MaterialeAnagraficaSelezionato is not null)
            {
                if (MaterialiAnagrafica.All(x => x.IdMateriale != IdMaterialeSelezionato))
                    MaterialiAnagrafica = MaterialiAnagrafica.Append(MaterialeAnagraficaSelezionato).ToArray();
                if (inizializza)
                    ApplicaMaterialeAnagrafica(MaterialeAnagraficaSelezionato);
            }
        }

        NuovoMateriale.IdRigaPreventivo = idRigaPreventivo;
        NuovoMateriale.IdRigaCompPrev = Componente?.IdRigaCompPrev;
        NuovoMateriale.IdNodoDistinta = Componente?.IdNodoDistinta;

        if (inizializza && NuovoMateriale.Quantita == 0)
        {
            NuovoMateriale.Quantita = 1;
        }
        if (inizializza && NuovoMateriale.IdFornitoreSuggerito.HasValue &&
            Fornitori.All(x => x.IdFornitore != NuovoMateriale.IdFornitoreSuggerito))
            NuovoMateriale.IdFornitoreSuggerito = null;
    }

    private void ApplicaMaterialeDistinta(
        DistintaMaterialeLookupItem materiale, bool inizializza = true)
    {
        NuovoMateriale.IdMateriale = materiale.IdMateriale;
        NuovoMateriale.DescrizioneMateriale = materiale.DescrizioneMateriale;
        NuovoMateriale.TipoMateriale = materiale.TipoMateriale;
        NuovoMateriale.UM = materiale.UM;
        if (!inizializza) return;
        NuovoMateriale.Quantita = materiale.Quantita;
        NuovoMateriale.CostoUnitario = materiale.CostoUnitario;
        NuovoMateriale.DaAcquistare = materiale.DaAcquistare;
        NuovoMateriale.IdFornitoreSuggerito = materiale.IdFornitoreSuggerito;
    }

    private void ApplicaMaterialeAnagrafica(
        MaterialeLookupItem materiale, bool inizializza = true)
    {
        NuovoMateriale.IdMateriale = materiale.IdMateriale;
        NuovoMateriale.DescrizioneMateriale = materiale.Descrizione;
        NuovoMateriale.TipoMateriale = materiale.TipoMateriale;
        NuovoMateriale.UM = materiale.UM;
        if (!inizializza) return;
        NuovoMateriale.CostoUnitario = materiale.CostoUnitario;
        NuovoMateriale.DaAcquistare = materiale.GestitoAAcquisto;
        NuovoMateriale.IdFornitoreSuggerito = materiale.IdFornitorePredefinito;
    }

    private void NormalizeOrigine()
    {
        if (string.Equals(Origine, OrigineDistinta, StringComparison.OrdinalIgnoreCase))
        {
            Origine = OrigineDistinta;
            return;
        }

        if (string.Equals(Origine, OrigineAnagrafica, StringComparison.OrdinalIgnoreCase))
        {
            Origine = OrigineAnagrafica;
            return;
        }

        Origine = OrigineLibero;
    }

    private async Task<bool> RigaAppartieneAlPreventivoAsync(
        int idPreventivo,
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        var preventivo =
            await _preventivoRepository.GetDettaglioAsync(
                idPreventivo,
                cancellationToken);
        if (preventivo is null)
        {
            return false;
        }

        var riga =
            await _preventivoRepository.GetRigaAsync(
                idRigaPreventivo,
                cancellationToken);

        return riga?.IdPreventivo == idPreventivo;
    }

    public static string GetMaterialeReturnUrl(
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente,
        int idMateriale)
    {
        return $"/Preventivi/Riga/Materiali?modo=dettaglio&idPreventivo={idPreventivo}&idRigaPreventivo={idRigaPreventivo}&idComponente={idComponente}&id={idMateriale}";
    }

    public static bool IsNuovo(string modo) =>
        string.Equals(modo, "nuovo", StringComparison.OrdinalIgnoreCase);

    public static bool IsElimina(string modo) =>
        string.Equals(modo, "elimina", StringComparison.OrdinalIgnoreCase);

    public static bool IsDettaglio(string modo) =>
        string.Equals(modo, "dettaglio", StringComparison.OrdinalIgnoreCase);

    private static bool IsRequestValid(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente,
        int? id)
    {
        if (idPreventivo <= 0 ||
            idRigaPreventivo <= 0 ||
            idComponente <= 0)
        {
            return false;
        }

        if (IsNuovo(modo))
        {
            return true;
        }

        return (IsDettaglio(modo) || IsElimina(modo)) &&
            id is > 0;
    }
}

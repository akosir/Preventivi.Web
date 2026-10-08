using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class ComponentiModel : PageModel
{
    public const string OrigineDistinta = "Distinta";
    public const string OrigineArticolo = "Articolo";
    public const string OrigineLibero = "Libero";

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IAllegatoRepository _allegatoRepository;

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    public IReadOnlyList<PreventivoRigaMaterialeItem> Materiali { get; private set; }
        = Array.Empty<PreventivoRigaMaterialeItem>();

    public IReadOnlyList<PreventivoRigaLavorazioneItem> Lavorazioni { get; private set; }
        = Array.Empty<PreventivoRigaLavorazioneItem>();

    public AllegatiGridModel Allegati { get; private set; } = new();

    public IReadOnlyList<ArticoloLookupItem> Articoli { get; private set; }
        = Array.Empty<ArticoloLookupItem>();

    public IReadOnlyList<DistintaNodoLookupItem> NodiDistinta { get; private set; }
        = Array.Empty<DistintaNodoLookupItem>();

    public ArticoloLookupItem? ArticoloSelezionato { get; private set; }

    public DistintaNodoLookupItem? NodoDistintaSelezionato { get; private set; }

    [BindProperty(SupportsGet = true)]
    public string Origine { get; set; } = OrigineLibero;

    [BindProperty(SupportsGet = true)]
    public string? RicercaArticolo { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdArticoloSelezionato { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdNodoDistintaSelezionato { get; set; }

    [BindProperty]
    public PreventivoRigaComponenteCreateModel NuovoComponente { get; set; } = new();

    public ComponentiModel(
        IPreventivoRepository preventivoRepository,
        IAllegatoRepository allegatoRepository)
    {
        _preventivoRepository = preventivoRepository;
        _allegatoRepository = allegatoRepository;
    }

    public async Task<IActionResult> OnGetAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, id))
        {
            return BadRequest();
        }

        if (IsNuovo(modo))
        {
            await PreparaNuovoComponenteAsync(
                idRigaPreventivo,
                cancellationToken);

            return Page();
        }

        Componente =
            await _preventivoRepository.GetComponenteAsync(
                id!.Value,
                cancellationToken);

        if (Componente is null ||
            Componente.IdRigaPreventivo != idRigaPreventivo)
        {
            return NotFound();
        }

        if (IsDettaglio(modo))
        {
            Materiali =
                await _preventivoRepository.GetMaterialiAsync(
                    idRigaPreventivo,
                    Componente.IdNodoDistinta,
                    cancellationToken);

            Lavorazioni =
                await _preventivoRepository.GetLavorazioniAsync(
                    idRigaPreventivo,
                    Componente.IdNodoDistinta,
                    cancellationToken);

            Allegati = new AllegatiGridModel
            {
                Allegati =
                    await _allegatoRepository.GetElencoAsync(
                        "PreventiviRigheComponenti",
                        Componente.IdRigaCompPrev,
                        cancellationToken),
                ReturnUrl = GetComponentiReturnUrl(
                    idPreventivo,
                    idRigaPreventivo,
                    Componente.IdRigaCompPrev)
            };
        }

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
        string modo,
        int idPreventivo,
        int idRigaPreventivo,
        int? id,
        CancellationToken cancellationToken)
    {
        if (!IsRequestValid(modo, idPreventivo, idRigaPreventivo, id))
        {
            return BadRequest();
        }

        if (IsElimina(modo))
        {
            await _preventivoRepository.EliminaComponenteAsync(
                id!.Value,
                cancellationToken);

            return RedirectToWorkspace(idPreventivo, idRigaPreventivo);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        NormalizeOrigine();

        await PreparaNuovoComponenteAsync(
            idRigaPreventivo,
            cancellationToken);

        if (Origine == OrigineDistinta)
        {
            if (IdNodoDistintaSelezionato is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdNodoDistintaSelezionato),
                    "Selezionare un nodo distinta.");
            }
            else if (NodoDistintaSelezionato is null)
            {
                ModelState.AddModelError(
                    nameof(IdNodoDistintaSelezionato),
                    "Nodo distinta non trovato.");
            }
            else
            {
                ApplicaNodoDistinta(NodoDistintaSelezionato);
            }
        }

        if (Origine == OrigineArticolo)
        {
            if (IdArticoloSelezionato is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdArticoloSelezionato),
                    "Selezionare un articolo.");
            }
            else if (ArticoloSelezionato is null)
            {
                ModelState.AddModelError(
                    nameof(IdArticoloSelezionato),
                    "Articolo non trovato.");
            }
            else if (string.IsNullOrWhiteSpace(NuovoComponente.DescrizioneNodo))
            {
                NuovoComponente.DescrizioneNodo = ArticoloSelezionato.Display;
            }
        }

        if (string.IsNullOrWhiteSpace(NuovoComponente.DescrizioneNodo))
        {
            ModelState.AddModelError(
                nameof(NuovoComponente.DescrizioneNodo),
                "La descrizione del componente e obbligatoria.");
        }

        NuovoComponente.IdRigaPreventivo = idRigaPreventivo;

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idComponente =
            await _preventivoRepository.CreaComponenteAsync(
                NuovoComponente,
                cancellationToken);

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

    public IActionResult RedirectToWorkspace(
        int idPreventivo,
        int idRigaPreventivo)
    {
        return RedirectToPage(
            "/Preventivi/Riga/Workspace",
            new
            {
                idPreventivo,
                idRigaPreventivo
            });
    }

    private async Task PreparaNuovoComponenteAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken)
    {
        NormalizeOrigine();

        Articoli =
            await _preventivoRepository.CercaArticoliAsync(
                RicercaArticolo,
                cancellationToken);

        if (IdArticoloSelezionato is > 0)
        {
            ArticoloSelezionato =
                await _preventivoRepository.GetArticoloAsync(
                    IdArticoloSelezionato.Value,
                    cancellationToken);

            NodiDistinta =
                await _preventivoRepository.GetNodiDistintaAsync(
                    IdArticoloSelezionato.Value,
                    cancellationToken);
        }

        if (IdNodoDistintaSelezionato is > 0)
        {
            NodoDistintaSelezionato =
                await _preventivoRepository.GetNodoDistintaAsync(
                    IdNodoDistintaSelezionato.Value,
                    cancellationToken);

            if (NodoDistintaSelezionato is not null)
            {
                IdArticoloSelezionato = NodoDistintaSelezionato.IdArticolo;
                ApplicaNodoDistinta(NodoDistintaSelezionato);
            }
        }

        NuovoComponente.IdRigaPreventivo = idRigaPreventivo;

        if (NuovoComponente.QuantitaBase == 0)
        {
            NuovoComponente.QuantitaBase = 1;
        }

        if (NuovoComponente.QuantitaCalcolata == 0)
        {
            NuovoComponente.QuantitaCalcolata = NuovoComponente.QuantitaBase;
        }

        if (NuovoComponente.OrdineVisualizzazione is null)
        {
            NuovoComponente.OrdineVisualizzazione = 10;
        }
    }

    private void ApplicaNodoDistinta(
        DistintaNodoLookupItem nodo)
    {
        NuovoComponente.IdNodoDistinta = nodo.IdNodoDistinta;
        NuovoComponente.IdNodoPadre = nodo.IdNodoPadre;
        NuovoComponente.DescrizioneNodo = nodo.DescrizioneNodo;
        NuovoComponente.Livello = nodo.Livello;
        NuovoComponente.QuantitaBase = nodo.QuantitaBase;
        NuovoComponente.QuantitaCalcolata = nodo.QuantitaBase;
        NuovoComponente.OrdineVisualizzazione = nodo.OrdineVisualizzazione;
    }

    private void NormalizeOrigine()
    {
        if (string.Equals(Origine, OrigineDistinta, StringComparison.OrdinalIgnoreCase))
        {
            Origine = OrigineDistinta;
            return;
        }

        if (string.Equals(Origine, OrigineArticolo, StringComparison.OrdinalIgnoreCase))
        {
            Origine = OrigineArticolo;
            return;
        }

        Origine = OrigineLibero;
    }

    public static string GetComponentiReturnUrl(
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente)
    {
        return $"/Preventivi/Riga/Componenti?modo=dettaglio&idPreventivo={idPreventivo}&idRigaPreventivo={idRigaPreventivo}&id={idComponente}";
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
        int? id)
    {
        if (idPreventivo <= 0 ||
            idRigaPreventivo <= 0)
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

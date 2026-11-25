using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using IAnagraficheProduttiveRepository = Preventivi.Core.Anagrafiche.IAnagraficheProduttiveRepository;
using Preventivi.Core.Preventivi;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class LavorazioniModel : PageModel
{
    public const string OrigineDistinta = "Distinta";
    public const string OrigineAnagrafica = "Anagrafica";
    public const string OrigineLibero = "Libero";

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IAnagraficheProduttiveRepository _anagraficheRepository;
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IPreventivoEliminazioneService _eliminazioneService;

    public PreventivoRigaLavorazioneItem? Lavorazione { get; private set; }

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    public AllegatiGridModel Allegati { get; private set; } = new();

    public IReadOnlyList<DistintaLavorazioneLookupItem> LavorazioniDistinta { get; private set; }
        = Array.Empty<DistintaLavorazioneLookupItem>();

    public IReadOnlyList<LavorazioneLookupItem> LavorazioniAnagrafica { get; private set; }
        = Array.Empty<LavorazioneLookupItem>();

    public IReadOnlyList<FornitoreLookupItem> Fornitori { get; private set; }
        = Array.Empty<FornitoreLookupItem>();

    public DistintaLavorazioneLookupItem? LavorazioneDistintaSelezionata { get; private set; }

    public LavorazioneLookupItem? LavorazioneAnagraficaSelezionata { get; private set; }

    [BindProperty(SupportsGet = true)]
    public string Origine { get; set; } = OrigineLibero;

    [BindProperty(SupportsGet = true)]
    public string? RicercaLavorazione { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdDistintaLavorazioneSelezionata { get; set; }

    [BindProperty(SupportsGet = true)]
    public int? IdLavorazioneSelezionata { get; set; }

    [BindProperty]
    public PreventivoRigaLavorazioneCreateModel NuovaLavorazione { get; set; } = new();

    public LavorazioniModel(
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
            await PreparaNuovaLavorazioneAsync(
                idRigaPreventivo,
                cancellationToken);

            return Page();
        }

        Lavorazione =
            await _preventivoRepository.GetLavorazioneAsync(
                id!.Value,
                cancellationToken);

        if (Lavorazione is null ||
            Lavorazione.IdRigaPreventivo != idRigaPreventivo ||
            Lavorazione.IdRigaCompPrev != Componente.IdRigaCompPrev)
        {
            return NotFound();
        }

        if (IsDettaglio(modo))
        {
            Allegati = new AllegatiGridModel
            {
                Allegati =
                    await _allegatoRepository.GetElencoAsync(
                        "PreventiviRigheLavorazioni",
                        Lavorazione.IdRigaLavPrev,
                        cancellationToken),
                ReturnUrl = GetLavorazioneReturnUrl(
                    idPreventivo,
                    idRigaPreventivo,
                    idComponente,
                    Lavorazione.IdRigaLavPrev)
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
            var lavorazione =
                await _preventivoRepository.GetLavorazioneAsync(
                    id!.Value,
                    cancellationToken);

            if (lavorazione is null ||
                lavorazione.IdRigaPreventivo != idRigaPreventivo ||
                lavorazione.IdRigaCompPrev != Componente.IdRigaCompPrev)
            {
                return NotFound();
            }

            try
            {
                await _eliminazioneService.EliminaAsync(
                    TipoEliminazionePreventivo.Lavorazione,
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
                Lavorazione = lavorazione;
                return Page();
            }

            return RedirectToComponente(idPreventivo, idRigaPreventivo, idComponente);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        await PreparaNuovaLavorazioneAsync(
            idRigaPreventivo,
            cancellationToken,
            inizializza: false);

        if (Origine == OrigineDistinta)
        {
            if (IdDistintaLavorazioneSelezionata is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdDistintaLavorazioneSelezionata),
                    "Selezionare una lavorazione della distinta.");
            }
            else if (LavorazioneDistintaSelezionata is null)
            {
                ModelState.AddModelError(
                    nameof(IdDistintaLavorazioneSelezionata),
                    "Lavorazione distinta non trovata.");
            }
            else
            {
                ApplicaLavorazioneDistinta(LavorazioneDistintaSelezionata, inizializza: false);
            }
        }

        if (Origine == OrigineAnagrafica)
        {
            if (IdLavorazioneSelezionata is not > 0)
            {
                ModelState.AddModelError(
                    nameof(IdLavorazioneSelezionata),
                    "Selezionare una lavorazione.");
            }
            else if (LavorazioneAnagraficaSelezionata is null)
            {
                ModelState.AddModelError(
                    nameof(IdLavorazioneSelezionata),
                    "Lavorazione non trovata.");
            }
            else
            {
                ApplicaLavorazioneAnagrafica(LavorazioneAnagraficaSelezionata, inizializza: false);
            }
        }

        NuovaLavorazione.IdRigaPreventivo = idRigaPreventivo;
        NuovaLavorazione.IdRigaCompPrev = Componente.IdRigaCompPrev;
        NuovaLavorazione.IdNodoDistinta = Componente.IdNodoDistinta;

        if (Origine == OrigineLibero)
            NuovaLavorazione.IdLavorazione = null;
        else
        {
            ModelState.Remove("NuovaLavorazione.IdLavorazione");
            ModelState.Remove("NuovaLavorazione.DescrizioneLavorazione");
        }

        if (string.IsNullOrWhiteSpace(NuovaLavorazione.DescrizioneLavorazione))
            ModelState.AddModelError("NuovaLavorazione.DescrizioneLavorazione", "La descrizione della lavorazione e obbligatoria.");
        if (NuovaLavorazione.TempoSetupMin < 0 || NuovaLavorazione.TempoPezzoMin < 0 ||
            NuovaLavorazione.Quantita < 0 || NuovaLavorazione.CostoOrario < 0 || NuovaLavorazione.CostoFisso < 0)
            ModelState.AddModelError(string.Empty, "Tempi, quantita e costi non possono essere negativi.");
        if (NuovaLavorazione.IdFornitoreSuggerito.HasValue &&
            Fornitori.All(x => x.IdFornitore != NuovaLavorazione.IdFornitoreSuggerito))
            ModelState.AddModelError("NuovaLavorazione.IdFornitoreSuggerito", "Selezionare un fornitore attivo disponibile.");

        global::Preventivi.Web.UI.ValidazioneLunghezzeTesto.ValidaLunghezzeTesto(ModelState, NuovaLavorazione, "NuovaLavorazione");
        if (!ModelState.IsValid)
        {
            return Page();
        }

        var idLavorazione =
            await _preventivoRepository.CreaLavorazioneAsync(
                NuovaLavorazione,
                cancellationToken);

        return RedirectToPage(
            "/Preventivi/Riga/Lavorazioni",
            new
            {
                modo = "dettaglio",
                idPreventivo,
                idRigaPreventivo,
                idComponente,
                id = idLavorazione
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

    private async Task PreparaNuovaLavorazioneAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken,
        bool inizializza = true)
    {
        if (!inizializza && !new[] { OrigineDistinta, OrigineAnagrafica, OrigineLibero }
                .Contains(Origine, StringComparer.OrdinalIgnoreCase))
            ModelState.AddModelError(nameof(Origine), "Selezionare un'origine lavorazione valida.");
        NormalizeOrigine();

        if (Componente?.IdNodoDistinta is > 0)
        {
            LavorazioniDistinta =
                await _preventivoRepository.GetLavorazioniDistintaAsync(
                    Componente.IdNodoDistinta.Value,
                    cancellationToken);
        }

        LavorazioniAnagrafica =
            await _preventivoRepository.CercaLavorazioniAsync(
                RicercaLavorazione,
                cancellationToken);

        Fornitori =
            await _preventivoRepository.GetFornitoriAsync(cancellationToken);

        var lavorazioniAttive = await _anagraficheRepository.GetLavorazioniAsync(
            soloAttive: true, cancellationToken: cancellationToken);
        var idAttivi = lavorazioniAttive.Select(x => x.IdLavorazione).ToHashSet();
        LavorazioniDistinta = LavorazioniDistinta.Where(x => idAttivi.Contains(x.IdLavorazione)).ToArray();
        LavorazioniAnagrafica = LavorazioniAnagrafica.Where(x => idAttivi.Contains(x.IdLavorazione)).ToArray();

        if (Origine == OrigineDistinta && IdDistintaLavorazioneSelezionata is > 0)
        {
            LavorazioneDistintaSelezionata =
                LavorazioniDistinta.FirstOrDefault(x =>
                    x.IdDistintaLavorazione == IdDistintaLavorazioneSelezionata &&
                    x.IdNodoDistinta == Componente?.IdNodoDistinta);

            if (inizializza && LavorazioneDistintaSelezionata is not null)
            {
                ApplicaLavorazioneDistinta(LavorazioneDistintaSelezionata);
            }
        }

        if (Origine == OrigineAnagrafica && IdLavorazioneSelezionata is > 0 &&
            idAttivi.Contains(IdLavorazioneSelezionata.Value))
        {
            LavorazioneAnagraficaSelezionata =
                await _preventivoRepository.GetLavorazioneAnagraficaAsync(
                    IdLavorazioneSelezionata.Value,
                    cancellationToken);

            if (LavorazioneAnagraficaSelezionata is not null)
            {
                if (LavorazioniAnagrafica.All(x => x.IdLavorazione != IdLavorazioneSelezionata))
                    LavorazioniAnagrafica = LavorazioniAnagrafica.Append(LavorazioneAnagraficaSelezionata).ToArray();
                if (inizializza)
                    ApplicaLavorazioneAnagrafica(LavorazioneAnagraficaSelezionata);
            }
        }

        NuovaLavorazione.IdRigaPreventivo = idRigaPreventivo;
        NuovaLavorazione.IdRigaCompPrev = Componente?.IdRigaCompPrev;
        NuovaLavorazione.IdNodoDistinta = Componente?.IdNodoDistinta;

        if (inizializza && NuovaLavorazione.Sequenza is null)
        {
            NuovaLavorazione.Sequenza = 10;
        }

        if (inizializza && NuovaLavorazione.Quantita == 0)
        {
            NuovaLavorazione.Quantita = 1;
        }
        if (inizializza && NuovaLavorazione.IdFornitoreSuggerito.HasValue &&
            Fornitori.All(x => x.IdFornitore != NuovaLavorazione.IdFornitoreSuggerito))
            NuovaLavorazione.IdFornitoreSuggerito = null;
    }

    private void ApplicaLavorazioneDistinta(
        DistintaLavorazioneLookupItem lavorazione, bool inizializza = true)
    {
        NuovaLavorazione.IdLavorazione = lavorazione.IdLavorazione;
        NuovaLavorazione.DescrizioneLavorazione = lavorazione.DescrizioneLavorazione;
        if (!inizializza) return;
        NuovaLavorazione.Sequenza = lavorazione.Sequenza;
        NuovaLavorazione.TempoSetupMin = lavorazione.TempoSetupMin;
        NuovaLavorazione.TempoPezzoMin = lavorazione.TempoPezzoMin;
        NuovaLavorazione.CostoOrario = lavorazione.CostoOrario;
        NuovaLavorazione.CostoFisso = lavorazione.CostoFisso;
        NuovaLavorazione.DaAcquistareEsterno = lavorazione.DaAcquistareEsterno;
        NuovaLavorazione.IdFornitoreSuggerito = lavorazione.IdFornitoreSuggerito;
    }

    private void ApplicaLavorazioneAnagrafica(
        LavorazioneLookupItem lavorazione, bool inizializza = true)
    {
        NuovaLavorazione.IdLavorazione = lavorazione.IdLavorazione;
        NuovaLavorazione.DescrizioneLavorazione = lavorazione.Descrizione;
        if (!inizializza) return;
        NuovaLavorazione.TempoSetupMin = lavorazione.TempoSetupMinDefault;
        NuovaLavorazione.TempoPezzoMin = lavorazione.TempoPezzoMinDefault;
        NuovaLavorazione.CostoOrario = lavorazione.CostoOrarioStandard;
        NuovaLavorazione.DaAcquistareEsterno = lavorazione.AcquistabileEsterna;
        NuovaLavorazione.IdFornitoreSuggerito = lavorazione.IdFornitorePredefinito;
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

    public static string GetLavorazioneReturnUrl(
        int idPreventivo,
        int idRigaPreventivo,
        int idComponente,
        int idLavorazione)
    {
        return $"/Preventivi/Riga/Lavorazioni?modo=dettaglio&idPreventivo={idPreventivo}&idRigaPreventivo={idRigaPreventivo}&idComponente={idComponente}&id={idLavorazione}";
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

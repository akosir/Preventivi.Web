using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Allegati;

namespace Preventivi.Web.Pages.Preventivi.Riga;

public class LavorazioniModel : PageModel
{
    public const string OrigineDistinta = "Distinta";
    public const string OrigineAnagrafica = "Anagrafica";
    public const string OrigineLibero = "Libero";

    private readonly IPreventivoRepository _preventivoRepository;
    private readonly IAllegatoRepository _allegatoRepository;

    public PreventivoRigaLavorazioneItem? Lavorazione { get; private set; }

    public PreventivoRigaComponenteItem? Componente { get; private set; }

    public AllegatiGridModel Allegati { get; private set; } = new();

    public IReadOnlyList<DistintaLavorazioneLookupItem> LavorazioniDistinta { get; private set; }
        = Array.Empty<DistintaLavorazioneLookupItem>();

    public IReadOnlyList<LavorazioneLookupItem> LavorazioniAnagrafica { get; private set; }
        = Array.Empty<LavorazioneLookupItem>();

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
        IAllegatoRepository allegatoRepository)
    {
        _preventivoRepository = preventivoRepository;
        _allegatoRepository = allegatoRepository;
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
            Lavorazione.IdNodoDistinta != Componente.IdNodoDistinta)
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
                lavorazione.IdNodoDistinta != Componente.IdNodoDistinta)
            {
                return NotFound();
            }

            await _preventivoRepository.EliminaLavorazioneAsync(
                id.Value,
                cancellationToken);

            return RedirectToComponente(idPreventivo, idRigaPreventivo, idComponente);
        }

        if (!IsNuovo(modo))
        {
            return BadRequest();
        }

        await PreparaNuovaLavorazioneAsync(
            idRigaPreventivo,
            cancellationToken);

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
                ApplicaLavorazioneDistinta(LavorazioneDistintaSelezionata);
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
                ApplicaLavorazioneAnagrafica(LavorazioneAnagraficaSelezionata);
            }
        }

        if (string.IsNullOrWhiteSpace(NuovaLavorazione.DescrizioneLavorazione))
        {
            ModelState.AddModelError(
                nameof(NuovaLavorazione.DescrizioneLavorazione),
                "La descrizione della lavorazione e obbligatoria.");
        }

        NuovaLavorazione.IdRigaPreventivo = idRigaPreventivo;
        NuovaLavorazione.IdNodoDistinta = Componente.IdNodoDistinta;

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
        CancellationToken cancellationToken)
    {
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

        if (IdDistintaLavorazioneSelezionata is > 0)
        {
            LavorazioneDistintaSelezionata =
                await _preventivoRepository.GetLavorazioneDistintaAsync(
                    IdDistintaLavorazioneSelezionata.Value,
                    cancellationToken);

            if (LavorazioneDistintaSelezionata is not null)
            {
                ApplicaLavorazioneDistinta(LavorazioneDistintaSelezionata);
            }
        }

        if (IdLavorazioneSelezionata is > 0)
        {
            LavorazioneAnagraficaSelezionata =
                await _preventivoRepository.GetLavorazioneAnagraficaAsync(
                    IdLavorazioneSelezionata.Value,
                    cancellationToken);

            if (LavorazioneAnagraficaSelezionata is not null &&
                Origine == OrigineAnagrafica)
            {
                ApplicaLavorazioneAnagrafica(LavorazioneAnagraficaSelezionata);
            }
        }

        NuovaLavorazione.IdRigaPreventivo = idRigaPreventivo;
        NuovaLavorazione.IdNodoDistinta = Componente?.IdNodoDistinta;

        if (NuovaLavorazione.Sequenza is null)
        {
            NuovaLavorazione.Sequenza = 10;
        }

        if (NuovaLavorazione.Quantita == 0)
        {
            NuovaLavorazione.Quantita = 1;
        }
    }

    private void ApplicaLavorazioneDistinta(
        DistintaLavorazioneLookupItem lavorazione)
    {
        NuovaLavorazione.IdLavorazione = lavorazione.IdLavorazione;
        NuovaLavorazione.DescrizioneLavorazione = lavorazione.DescrizioneLavorazione;
        NuovaLavorazione.Sequenza = lavorazione.Sequenza;
        NuovaLavorazione.TempoSetupMin = lavorazione.TempoSetupMin;
        NuovaLavorazione.TempoPezzoMin = lavorazione.TempoPezzoMin;
        NuovaLavorazione.CostoOrario = lavorazione.CostoOrario;
        NuovaLavorazione.CostoFisso = lavorazione.CostoFisso;
        NuovaLavorazione.DaAcquistareEsterno = lavorazione.DaAcquistareEsterno;
        NuovaLavorazione.IdFornitoreSuggerito = lavorazione.IdFornitoreSuggerito;
    }

    private void ApplicaLavorazioneAnagrafica(
        LavorazioneLookupItem lavorazione)
    {
        NuovaLavorazione.IdLavorazione = lavorazione.IdLavorazione;
        NuovaLavorazione.DescrizioneLavorazione = lavorazione.Descrizione;
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

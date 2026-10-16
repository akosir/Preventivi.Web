using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Web.UI.Modules.Allegati;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Data.Allegati;
using Preventivi.Web.Sicurezza;


namespace Preventivi.Web.Pages.Allegati;

public class NuovoModel : PageModel
{
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IAllegatoStorageService _storageService;
    private readonly ILogger<NuovoModel> _logger;

    public NuovoModel(
        IAllegatoRepository allegatoRepository,
        IAllegatoStorageService storageService,
        ILogger<NuovoModel> logger)
    {
        _allegatoRepository = allegatoRepository;
        _storageService = storageService;
        _logger = logger;
    }

    [BindProperty(SupportsGet = true)]
    public string Entita { get; set; } = "";

    [BindProperty(SupportsGet = true)]
    public int IdEntita { get; set; }

    [BindProperty(SupportsGet = true)]
    public string? ReturnUrl { get; set; }

    [BindProperty]
    public AllegatoFormModel Form { get; set; } = new();


    public async Task<IActionResult> OnGetAsync(
        CancellationToken cancellationToken)
    {
        if (!AllegatoEntita.IsValida(Entita))
        {
            return BadRequest("Entità non valida.");
        }

        if (!AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(User, Entita))
        {
            return Forbid();
        }

        if (IdEntita <= 0)
        {
            return BadRequest("IdEntità non valido.");
        }

        Form.TipiAllegato =
    await _allegatoRepository.GetTipiAsync(
        cancellationToken);

        return Page();
    }

    public async Task<IActionResult> OnPostAsync(
    CancellationToken cancellationToken)
    {
        if (!AllegatoEntita.IsValida(Entita))
        {
            ModelState.AddModelError(
                string.Empty,
                "Entità non valida.");
        }
        else if (!AutorizzazioneApplicazione.PuoAccedereAllEntitaAllegato(User, Entita))
        {
            return Forbid();
        }

        if (IdEntita <= 0)
        {
            ModelState.AddModelError(
                string.Empty,
                "IdEntità non valido.");
        }

        if (string.IsNullOrWhiteSpace(Form.TipoAllegato))
        {
            ModelState.AddModelError(
                "Form.TipoAllegato",
                "Selezionare il tipo di allegato.");
        }

        if (Form.File is null || Form.File.Length == 0)
        {
            ModelState.AddModelError(
                "Form.File",
                "Selezionare un file da allegare.");
        }

        if (!ModelState.IsValid)
        {
            Form.TipiAllegato =
                await _allegatoRepository.GetTipiAsync(
                    cancellationToken);

            return Page();
        }

        var nomeFileOriginale =
    Path.GetFileName(Form.File!.FileName);

        var fileTemporaneo =
            Path.Combine(
                Path.GetTempPath(),
                $"{Guid.NewGuid():D}{Path.GetExtension(nomeFileOriginale)}");

        await using (var stream =
            new FileStream(
                fileTemporaneo,
                FileMode.Create,
                FileAccess.Write,
                FileShare.None,
                81920,
                useAsync: true))
        {
            await Form.File.CopyToAsync(
                stream,
                cancellationToken);
        }

        StorageSaveResult storageResult;

        try
        {
            storageResult =
                await _storageService.SalvaAsync(
                    new StorageSaveRequest
                    {
                        Entita = Entita,
                        IdEntita = IdEntita,
                        FileOrigine = fileTemporaneo,
                        NomeFileOriginale = nomeFileOriginale
                    },
                    cancellationToken);

            var nuovoAllegato = new AllegatoCreateModel
            {
                Entita = Entita,
                IdEntita = IdEntita,
                TipoAllegato = Form.TipoAllegato,
                Descrizione = Form.Descrizione,
                NomeFileOriginale = storageResult.NomeFileOriginale,
                PercorsoFile = storageResult.PercorsoRelativo,
                Estensione = storageResult.Estensione,
                DataAllegato = DateOnly.FromDateTime(DateTime.Today),
                UtenteInserimento = User.Identity?.Name ?? "Sistema",
                Note = Form.Note,
                NomeFileArchiviato = storageResult.NomeFileArchiviato,
                DimensioneFile = storageResult.DimensioneFile
            };

            await _allegatoRepository.CreaAsync(
                nuovoAllegato,
                cancellationToken);

            TempData["MessaggioSuccesso"] =
                "Allegato inserito correttamente.";

            if (Entita == AllegatoEntita.Clienti)
            {
                return RedirectToPage(
                    "/Clienti/Dettaglio",
                    new
                    {
                        IdCliente = IdEntita
                    });
            }

            if (Entita == AllegatoEntita.Preventivi)
            {
                return RedirectToPage(
                    "/Preventivi/Dettaglio",
                    new
                    {
                        id = IdEntita
                    });
            }

            if (IsLocalReturnUrl(ReturnUrl))
            {
                return LocalRedirect(ReturnUrl!);
            }

            return RedirectToPage();
        }
        catch (AllegatoStorageException exception)
        {
            _logger.LogError(
                exception,
                "Errore storage durante il salvataggio dell'allegato per {Entita} {IdEntita}.",
                Entita,
                IdEntita);

            ModelState.AddModelError(
                string.Empty,
                "Non è stato possibile salvare l'allegato. Verificare la configurazione dello storage.");

            Form.TipiAllegato =
                await _allegatoRepository.GetTipiAsync(cancellationToken);

            return Page();
        }
        finally
        {
            if (System.IO.File.Exists(fileTemporaneo))
            {
                System.IO.File.Delete(fileTemporaneo);
            }
        }

    }

    private static bool IsLocalReturnUrl(string? returnUrl)
    {
        return !string.IsNullOrWhiteSpace(returnUrl) &&
            returnUrl.StartsWith("/", StringComparison.Ordinal) &&
            !returnUrl.StartsWith("//", StringComparison.Ordinal);
    }
}

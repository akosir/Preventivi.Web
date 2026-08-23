using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Data.Allegati;

namespace Preventivi.Web.Pages.Dev.Allegati;

public class RepositoryModel : PageModel
{
    private readonly IAllegatoRepository _allegatoRepository;
    private readonly IAllegatoStorageService _storageService;

    [BindProperty]
    public string Entita { get; set; } = "Clienti";

    [BindProperty]
    public int IdEntita { get; set; }

    [BindProperty]
    public string TipoAllegato { get; set; } = "";

    [BindProperty]
    public string Descrizione { get; set; } = "";

    [BindProperty]
    public string FileOrigine { get; set; } = "";

    public RepositoryModel(
        IAllegatoRepository allegatoRepository,
        IAllegatoStorageService storageService)
    {
        _allegatoRepository = allegatoRepository;
        _storageService = storageService;
    }

    [BindProperty]
    public int IdAllegatoDisattiva { get; set; }

    public string? Esito { get; set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostDisattivaAsync(
    CancellationToken cancellationToken)
    {
        if (IdAllegatoDisattiva <= 0)
        {
            Esito = "Inserire un IdAllegato valido.";

            return Page();
        }

        await _allegatoRepository.DisattivaAsync(
            IdAllegatoDisattiva,
            cancellationToken);

        Esito =
            $"Allegato {IdAllegatoDisattiva} disattivato correttamente.";

        return Page();
    }

    public async Task<IActionResult> OnPostCreaAsync(
    CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(FileOrigine))
        {
            Esito = "Specificare un file sorgente.";

            return Page();
        }

        var nomeFileOriginale =
            Path.GetFileName(FileOrigine);

        var storageResult =
            await _storageService.SalvaAsync(
                new StorageSaveRequest
                {
                    Entita = Entita,
                    IdEntita = IdEntita,
                    FileOrigine = FileOrigine,
                    NomeFileOriginale = nomeFileOriginale
                },
                cancellationToken);

        var allegato = new AllegatoCreateModel
        {
            Entita = Entita,
            IdEntita = IdEntita,
            TipoAllegato =
                string.IsNullOrWhiteSpace(TipoAllegato)
                    ? null
                    : TipoAllegato.Trim(),

            Descrizione =
                string.IsNullOrWhiteSpace(Descrizione)
                    ? null
                    : Descrizione.Trim(),

            NomeFileOriginale =
                storageResult.NomeFileOriginale,

            NomeFileArchiviato =
                storageResult.NomeFileArchiviato,

            PercorsoFile =
                storageResult.PercorsoRelativo,

            Estensione =
                storageResult.Estensione,

            DataAllegato =
                DateOnly.FromDateTime(DateTime.Today),

            DimensioneFile = storageResult.DimensioneFile

        };

        var idAllegato =
            await _allegatoRepository.CreaAsync(
                allegato,
                cancellationToken);

        Esito =
            $"Allegato creato correttamente. IdAllegato = {idAllegato}";

        return Page();
    }
}

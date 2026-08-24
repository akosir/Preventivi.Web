using Microsoft.Extensions.Options;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.ParametriSistema;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoStorageService : IAllegatoStorageService
{

    private readonly IParametriSistemaRepository _parametriRepository;

    public AllegatoStorageService(
    IParametriSistemaRepository parametriRepository)
    {
        _parametriRepository = parametriRepository;
    }

    public async Task<StorageSaveResult> SalvaAsync(
    StorageSaveRequest request,
    CancellationToken cancellationToken = default)
    {
        var percorsoRoot =
await GetPercorsoRootAsync(
    cancellationToken);

        if (string.IsNullOrWhiteSpace(percorsoRoot))
        {
            throw new InvalidOperationException(
                "La cartella ArchivioAllegati non è configurata.");
        }

        if (string.IsNullOrWhiteSpace(request.Entita))
        {
            throw new ArgumentException(
                "Entità non valida.",
                nameof(request));
        }

        if (request.IdEntita <= 0)
        {
            throw new ArgumentException(
                "IdEntità non valido.",
                nameof(request));
        }

        if (string.IsNullOrWhiteSpace(request.FileOrigine))
        {
            throw new ArgumentException(
                "File origine non specificato.",
                nameof(request));
        }

        if (!File.Exists(request.FileOrigine))
        {
            throw new FileNotFoundException(
                "Il file da archiviare non esiste.",
                request.FileOrigine);
        }

        var anno = DateTime.Now.Year.ToString();

        var percorsoRelativo = Path.Combine(
            request.Entita,
            anno,
            request.IdEntita.ToString());

        var cartellaCompleta = Path.Combine(
            percorsoRoot,
            percorsoRelativo);

        Directory.CreateDirectory(cartellaCompleta);

        var estensione =
            Path.GetExtension(request.NomeFileOriginale);

        var nomeFileArchiviato =
            $"{Guid.NewGuid():D}{estensione}";

        var percorsoDestinazione = Path.Combine(
            cartellaCompleta,
            nomeFileArchiviato);

        await using (
            var sorgente = new FileStream(
                request.FileOrigine,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                81920,
                useAsync: true))
        {
            await using var destinazione =
                new FileStream(
                    percorsoDestinazione,
                    FileMode.CreateNew,
                    FileAccess.Write,
                    FileShare.None,
                    81920,
                    useAsync: true);

            await sorgente.CopyToAsync(
                destinazione,
                cancellationToken);
        }

        var infoFile =
            new FileInfo(percorsoDestinazione);

        return new StorageSaveResult
        {
            PercorsoRelativo = percorsoRelativo,

            NomeFileArchiviato = nomeFileArchiviato,

            NomeFileOriginale =
                request.NomeFileOriginale,

            Estensione = estensione,

            DimensioneFile = infoFile.Length
        };
    }

    public async Task<StorageFileResult> ApriAsync(
    StorageOpenRequest request,
    CancellationToken cancellationToken = default)
    {
        var percorsoRoot =
            await GetPercorsoRootAsync(
                cancellationToken);

        if (string.IsNullOrWhiteSpace(request.PercorsoRelativo))
        {
            throw new ArgumentException(
                "Percorso relativo non valido.",
                nameof(request));
        }

        if (string.IsNullOrWhiteSpace(request.NomeFileArchiviato))
        {
            throw new ArgumentException(
                "Nome file archiviato non valido.",
                nameof(request));
        }

        var percorsoCompleto = Path.Combine(
            percorsoRoot,
            request.PercorsoRelativo,
            request.NomeFileArchiviato);

        if (!File.Exists(percorsoCompleto))
        {
            throw new FileNotFoundException(
                "Il file allegato non è stato trovato nello storage.",
                percorsoCompleto);
        }

        Stream stream = new FileStream(
            percorsoCompleto,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            81920,
            useAsync: true);

        var infoFile =
            new FileInfo(percorsoCompleto);

        return new StorageFileResult
        {
            Stream = stream,
            NomeFileOriginale = request.NomeFileOriginale,
            Estensione = Path.GetExtension(request.NomeFileOriginale),
            DimensioneFile = infoFile.Length
        };
    }

    public async Task EliminaAsync(
    string percorsoRelativo,
    string nomeFileArchiviato,
    CancellationToken cancellationToken = default)
    {
        var percorsoRoot =
            await GetPercorsoRootAsync(
                cancellationToken);

        if (string.IsNullOrWhiteSpace(percorsoRelativo))
        {
            throw new ArgumentException(
                "Percorso relativo non valido.",
                nameof(percorsoRelativo));
        }

        if (string.IsNullOrWhiteSpace(nomeFileArchiviato))
        {
            throw new ArgumentException(
                "Nome file archiviato non valido.",
                nameof(nomeFileArchiviato));
        }

        var percorsoCompleto =
            Path.Combine(
                percorsoRoot,
                percorsoRelativo,
                nomeFileArchiviato);

        if (!File.Exists(percorsoCompleto))
        {
            return;
        }

        File.Delete(percorsoCompleto);
    }

    private async Task<string> GetPercorsoRootAsync(
    CancellationToken cancellationToken)
    {
        var percorso =
            await _parametriRepository.GetValoreAsync(
                "PercorsoRootAllegati",
                cancellationToken);

        if (string.IsNullOrWhiteSpace(percorso))
        {
            throw new InvalidOperationException(
                "Il parametro 'PercorsoRootAllegati' non è configurato.");
        }

        return percorso.Trim();
    }
}

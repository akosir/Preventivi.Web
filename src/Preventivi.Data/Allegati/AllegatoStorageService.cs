using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Storage;
using Preventivi.Core.ParametriSistema;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoStorageService : IAllegatoStorageService
{
    private const string ChiavePercorsoRoot = "PercorsoRootAllegati";
    private const string CartellaQuarantena = ".quarantena";

    private readonly IParametriSistemaRepository _parametriRepository;

    public AllegatoStorageService(IParametriSistemaRepository parametriRepository)
    {
        _parametriRepository = parametriRepository;
    }

    public async Task<StorageSaveResult> SalvaAsync(
        StorageSaveRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!AllegatoEntita.IsValida(request.Entita))
        {
            throw new AllegatoStoragePathException(
                "La tipologia dell'entità allegata non è consentita.");
        }

        if (request.IdEntita <= 0)
        {
            throw new ArgumentException("IdEntità non valido.", nameof(request));
        }

        if (string.IsNullOrWhiteSpace(request.FileOrigine))
        {
            throw new ArgumentException("File origine non specificato.", nameof(request));
        }

        ValidaNomeFile(request.NomeFileOriginale, "nome del file originale");

        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var anno = DateTime.Now.Year.ToString();
        var percorsoRelativo = Path.Combine(
            request.Entita,
            anno,
            request.IdEntita.ToString());
        var cartellaCompleta = CostruisciPercorsoContenuto(
            percorsoRoot,
            percorsoRelativo);

        if (!File.Exists(request.FileOrigine))
        {
            throw new FileNotFoundException(
                "Il file da archiviare non esiste.",
                request.FileOrigine);
        }

        var estensione = Path.GetExtension(request.NomeFileOriginale);
        var nomeFileArchiviato = $"{Guid.NewGuid():D}{estensione}";
        var percorsoDestinazione = CostruisciPercorsoContenuto(
            percorsoRoot,
            percorsoRelativo,
            nomeFileArchiviato);

        try
        {
            Directory.CreateDirectory(cartellaCompleta);

            await using var sorgente = new FileStream(
                request.FileOrigine,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                81920,
                useAsync: true);
            await using var destinazione = new FileStream(
                percorsoDestinazione,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None,
                81920,
                useAsync: true);

            await sorgente.CopyToAsync(destinazione, cancellationToken);
        }
        catch (Exception exception)
        {
            try
            {
                File.Delete(percorsoDestinazione);
            }
            catch (Exception compensazioneException)
            {
                throw new AllegatoStorageOperationException(
                    "La copia dell'allegato non è riuscita e il file parziale non è stato rimosso.",
                    new AggregateException(exception, compensazioneException));
            }

            if (exception is OperationCanceledException)
            {
                throw;
            }

            throw new AllegatoStorageOperationException(
                "Non è stato possibile archiviare il file allegato.",
                exception);
        }

        var infoFile = new FileInfo(percorsoDestinazione);

        return new StorageSaveResult
        {
            PercorsoRelativo = percorsoRelativo,
            NomeFileArchiviato = nomeFileArchiviato,
            NomeFileOriginale = request.NomeFileOriginale,
            Estensione = estensione,
            DimensioneFile = infoFile.Length
        };
    }

    public async Task<StorageFileResult> ApriAsync(
        StorageOpenRequest request,
        CancellationToken cancellationToken = default)
    {
        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var percorsoCompleto = CostruisciPercorsoContenuto(
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

        var infoFile = new FileInfo(percorsoCompleto);

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
        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var percorsoCompleto = CostruisciPercorsoContenuto(
            percorsoRoot,
            percorsoRelativo,
            nomeFileArchiviato);

        if (File.Exists(percorsoCompleto))
        {
            File.Delete(percorsoCompleto);
        }
    }

    public async Task<StorageQuarantineResult?> SpostaInQuarantenaAsync(
        string percorsoRelativo,
        string nomeFileArchiviato,
        CancellationToken cancellationToken = default)
    {
        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var percorsoOriginale = CostruisciPercorsoContenuto(
            percorsoRoot,
            percorsoRelativo,
            nomeFileArchiviato);

        if (!File.Exists(percorsoOriginale))
        {
            return null;
        }

        var nomeFileQuarantena = $"{Guid.NewGuid():D}{Path.GetExtension(nomeFileArchiviato)}";
        var cartellaQuarantena = CostruisciPercorsoContenuto(
            percorsoRoot,
            CartellaQuarantena);
        var percorsoQuarantena = CostruisciPercorsoContenuto(
            percorsoRoot,
            CartellaQuarantena,
            nomeFileQuarantena);

        try
        {
            Directory.CreateDirectory(cartellaQuarantena);
            File.Move(percorsoOriginale, percorsoQuarantena);
        }
        catch (Exception exception)
        {
            throw new AllegatoStorageOperationException(
                "Non è stato possibile preparare il file per l'eliminazione.",
                exception);
        }

        return new StorageQuarantineResult
        {
            PercorsoRelativoOriginale = percorsoRelativo,
            NomeFileArchiviatoOriginale = nomeFileArchiviato,
            PercorsoRelativoQuarantena = CartellaQuarantena,
            NomeFileQuarantena = nomeFileQuarantena
        };
    }

    public async Task RipristinaDaQuarantenaAsync(
        StorageQuarantineResult fileInQuarantena,
        CancellationToken cancellationToken = default)
    {
        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var percorsoQuarantena = CostruisciPercorsoContenuto(
            percorsoRoot,
            fileInQuarantena.PercorsoRelativoQuarantena,
            fileInQuarantena.NomeFileQuarantena);
        var percorsoOriginale = CostruisciPercorsoContenuto(
            percorsoRoot,
            fileInQuarantena.PercorsoRelativoOriginale,
            fileInQuarantena.NomeFileArchiviatoOriginale);

        if (!File.Exists(percorsoQuarantena))
        {
            throw new FileNotFoundException(
                "Il file in quarantena non è disponibile per il ripristino.");
        }

        Directory.CreateDirectory(Path.GetDirectoryName(percorsoOriginale)!);
        File.Move(percorsoQuarantena, percorsoOriginale);
    }

    public async Task EliminaDaQuarantenaAsync(
        StorageQuarantineResult fileInQuarantena,
        CancellationToken cancellationToken = default)
    {
        var percorsoRoot = await GetPercorsoRootAsync(cancellationToken);
        var percorsoQuarantena = CostruisciPercorsoContenuto(
            percorsoRoot,
            fileInQuarantena.PercorsoRelativoQuarantena,
            fileInQuarantena.NomeFileQuarantena);

        File.Delete(percorsoQuarantena);
    }

    private async Task<string> GetPercorsoRootAsync(
        CancellationToken cancellationToken)
    {
        var percorso = await _parametriRepository.GetValoreAsync(
            ChiavePercorsoRoot,
            cancellationToken);

        if (string.IsNullOrWhiteSpace(percorso))
        {
            throw new AllegatoStorageConfigurationException(
                "La cartella degli allegati non è configurata.");
        }

        var percorsoNormalizzato = percorso.Trim();

        if (!Path.IsPathFullyQualified(percorsoNormalizzato))
        {
            throw new AllegatoStorageConfigurationException(
                "La cartella degli allegati deve essere un percorso assoluto.");
        }

        try
        {
            return Path.GetFullPath(percorsoNormalizzato);
        }
        catch (Exception exception) when (
            exception is ArgumentException or NotSupportedException or PathTooLongException)
        {
            throw new AllegatoStorageConfigurationException(
                "La configurazione della cartella degli allegati non è valida.");
        }
    }

    private static string CostruisciPercorsoContenuto(
        string percorsoRoot,
        string percorsoRelativo,
        string? nomeFileArchiviato = null)
    {
        ValidaPercorsoRelativo(percorsoRelativo);

        if (nomeFileArchiviato is not null)
        {
            ValidaNomeFile(nomeFileArchiviato, "nome del file archiviato");
        }

        string percorsoCompleto;

        try
        {
            percorsoCompleto = nomeFileArchiviato is null
                ? Path.GetFullPath(Path.Combine(percorsoRoot, percorsoRelativo))
                : Path.GetFullPath(Path.Combine(
                    percorsoRoot,
                    percorsoRelativo,
                    nomeFileArchiviato));
        }
        catch (Exception exception) when (
            exception is ArgumentException or NotSupportedException or PathTooLongException)
        {
            throw new AllegatoStoragePathException(
                "Il percorso dell'allegato non è valido.");
        }

        var separatore = Path.DirectorySeparatorChar.ToString();
        var rootConSeparatore = percorsoRoot.EndsWith(separatore, StringComparison.Ordinal)
            ? percorsoRoot
            : percorsoRoot + separatore;
        var confronto = OperatingSystem.IsWindows()
            ? StringComparison.OrdinalIgnoreCase
            : StringComparison.Ordinal;

        if (!percorsoCompleto.StartsWith(rootConSeparatore, confronto))
        {
            throw new AllegatoStoragePathException(
                "Il percorso dell'allegato non è contenuto nella cartella configurata.");
        }

        return percorsoCompleto;
    }

    private static void ValidaPercorsoRelativo(string percorsoRelativo)
    {
        if (string.IsNullOrWhiteSpace(percorsoRelativo) ||
            Path.IsPathFullyQualified(percorsoRelativo) ||
            percorsoRelativo.IndexOfAny(Path.GetInvalidPathChars()) >= 0)
        {
            throw new AllegatoStoragePathException(
                "Il percorso relativo dell'allegato non è valido.");
        }

        var segmenti = percorsoRelativo.Split(
            ['/', '\\'],
            StringSplitOptions.None);

        if (segmenti.Any(segmento =>
            string.IsNullOrWhiteSpace(segmento) ||
            segmento is "." or ".."))
        {
            throw new AllegatoStoragePathException(
                "Il percorso relativo dell'allegato contiene segmenti non consentiti.");
        }
    }

    private static void ValidaNomeFile(string nomeFile, string descrizione)
    {
        if (string.IsNullOrWhiteSpace(nomeFile) ||
            Path.IsPathFullyQualified(nomeFile) ||
            nomeFile is "." or ".." ||
            nomeFile.IndexOfAny(['/', '\\']) >= 0 ||
            nomeFile.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
        {
            throw new AllegatoStoragePathException(
                $"Il {descrizione} non è valido.");
        }
    }
}

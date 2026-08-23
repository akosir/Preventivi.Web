using Microsoft.Extensions.Options;
using Preventivi.Core.Allegati.Storage;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoStorageService : IAllegatoStorageService
{
    private readonly StorageOptions _options;

    public AllegatoStorageService(
        IOptions<StorageOptions> options)
    {
        _options = options.Value;
    }

    public async Task<StorageSaveResult> SalvaAsync(
    StorageSaveRequest request,
    CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ArchivioAllegati))
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
            _options.ArchivioAllegati,
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

    public Task<Stream> ApriAsync(
        string percorsoRelativo,
        string nomeFileArchiviato,
        CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }

    public Task EliminaAsync(
        string percorsoRelativo,
        string nomeFileArchiviato,
        CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException();
    }
}

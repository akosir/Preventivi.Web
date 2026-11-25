namespace Preventivi.Core.Anagrafiche;

public sealed record ArticoloImportazioneRiga(
    int RigaExcel, string CodiceArticolo, string Descrizione,
    string? Versione, string? CodiceCliente, string? NoteTecniche);

public sealed record ArticoliImportazioneErrore(string Foglio, int RigaExcel, string Campo, string Messaggio);

public sealed record ArticoliImportazioneRequest(
    Guid IdImportazione, string NomeFile, string ImprontaSha256,
    string Utente, IReadOnlyList<ArticoloImportazioneRiga> Righe);

public sealed class ArticoliImportazioneException(string messaggio) : Exception(messaggio);

public interface IArticoliImportazioneRepository
{
    Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(
        IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default);
    Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default);
}

public interface IArticoliImportazioneService
{
    Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(
        IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default);
    Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default);
}

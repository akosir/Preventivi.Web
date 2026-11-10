namespace Preventivi.Core.Anagrafiche;

public interface IDistintaBaseReportService
{
    Task<DistintaBasePdfResult?> GeneraPdfAsync(
        int idArticolo,
        CancellationToken cancellationToken = default);
}

public sealed record DistintaBasePdfResult(
    string NomeFile,
    byte[] Contenuto);

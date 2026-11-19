namespace Preventivi.Core.Anagrafiche;

public interface IDistintaBaseReportService
{
    Task<DistintaBasePdfResult?> GeneraPdfAsync(
        int idArticolo,
        int idRevisioneDistinta,
        CancellationToken cancellationToken = default);
}

public sealed record DistintaBasePdfResult(
    string NomeFile,
    byte[] Contenuto);

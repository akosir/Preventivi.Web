namespace Preventivi.Core.ParametriSistema;

public interface IParametriSistemaRepository
{
    Task<string?> GetValoreAsync(
        string chiave,
        CancellationToken cancellationToken = default);
}
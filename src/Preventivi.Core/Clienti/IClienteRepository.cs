namespace Preventivi.Core.Clienti;

public interface IClienteRepository
{
    Task<IReadOnlyList<ClienteListItem>> GetElencoAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default);

    Task<int> CreaAsync(
    ClienteCreateModel cliente,
    CancellationToken cancellationToken = default);

    Task<ClienteDettaglio?> GetByIdAsync(
    int idCliente,
    CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        ClienteUpdateModel cliente,
        CancellationToken cancellationToken = default);

    Task DisattivaAsync(
    int idCliente,
    CancellationToken cancellationToken = default);
}
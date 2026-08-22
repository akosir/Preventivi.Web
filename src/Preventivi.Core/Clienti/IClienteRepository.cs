namespace Preventivi.Core.Clienti;

public interface IClienteRepository
{
    Task<IReadOnlyList<ClienteListItem>> GetElencoAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default);
}
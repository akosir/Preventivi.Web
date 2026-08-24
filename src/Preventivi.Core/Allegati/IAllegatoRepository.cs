namespace Preventivi.Core.Allegati;

public interface IAllegatoRepository
{
    Task<IReadOnlyList<AllegatoListItem>> GetElencoAsync(
        string entita,
        int idEntita,
        CancellationToken cancellationToken = default);

    Task<AllegatoDettaglio?> GetByIdAsync(
        int idAllegato,
        CancellationToken cancellationToken = default);

    Task<int> CreaAsync(
        AllegatoCreateModel allegato,
        CancellationToken cancellationToken = default);

    Task EliminaAsync(
       int idAllegato,
       CancellationToken cancellationToken = default);

    Task<IReadOnlyList<TipoAllegatoItem>> GetTipiAsync(
        CancellationToken cancellationToken = default);
}
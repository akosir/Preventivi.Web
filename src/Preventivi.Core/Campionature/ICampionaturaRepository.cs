namespace Preventivi.Core.Campionature;

public interface ICampionaturaRepository
{
    Task<IReadOnlyList<CampionaturaListItem>> GetElencoAsync(
        CampionaturaFiltro filtro,
        CancellationToken cancellationToken = default);

    Task<CampionaturaDettaglio?> GetDettaglioAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaRichiestaLookupItem>> GetRichiesteAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaPreventivoLookupItem>> GetPreventiviAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaVarianteLookupItem>> GetVariantiAsync(
        CancellationToken cancellationToken = default);

    Task<int> CreaAsync(
        CampionaturaCreateModel campionatura,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        CampionaturaUpdateModel campionatura,
        CancellationToken cancellationToken = default);
}

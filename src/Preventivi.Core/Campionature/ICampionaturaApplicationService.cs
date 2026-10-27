namespace Preventivi.Core.Campionature;

public interface ICampionaturaApplicationService
{
    Task<int> CreaAsync(
        CampionaturaCreateModel campionatura,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        CampionaturaUpdateModel campionatura,
        CancellationToken cancellationToken = default);
}

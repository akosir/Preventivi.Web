namespace Preventivi.Core.Campionature;

public interface ICampionaturaApplicationService
{
    Task<int> CreaAsync(
        CampionaturaCreateModel campionatura,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        CampionaturaUpdateModel campionatura,
        CancellationToken cancellationToken = default);

    Task AggiornaStatoAsync(
        CampionaturaStatoUpdateModel campionatura,
        CancellationToken cancellationToken = default);

    Task<int> CreaRilievoAsync(
        CampionaturaRilievoCreateModel rilievo,
        CancellationToken cancellationToken = default);

    Task AggiornaStatoRilievoAsync(
        CampionaturaRilievoStatoUpdateModel rilievo,
        CancellationToken cancellationToken = default);

    Task AggiornaRilievoAsync(
        CampionaturaRilievoUpdateModel rilievo,
        CancellationToken cancellationToken = default);

    Task EliminaRilievoAsync(
        CampionaturaRilievoDeleteModel rilievo,
        CancellationToken cancellationToken = default);

    Task<int> CreaAdeguamentoAsync(
        CampionaturaAdeguamentoCreateModel adeguamento,
        CancellationToken cancellationToken = default);

    Task AggiornaAdeguamentoAsync(
        CampionaturaAdeguamentoUpdateModel adeguamento,
        CancellationToken cancellationToken = default);

    Task EliminaAdeguamentoAsync(
        CampionaturaAdeguamentoDeleteModel adeguamento,
        CancellationToken cancellationToken = default);

    Task<int> PreparaAdeguamentoAsync(
        CampionaturaAdeguamentoPreparaModel adeguamento,
        CancellationToken cancellationToken = default);

    Task AnnullaPreparazioneAdeguamentoAsync(
        CampionaturaAdeguamentoAnnullaPreparazioneModel adeguamento,
        CancellationToken cancellationToken = default);

    Task ConfermaAdeguamentoAsync(
        CampionaturaAdeguamentoConfermaModel adeguamento,
        CancellationToken cancellationToken = default);
}

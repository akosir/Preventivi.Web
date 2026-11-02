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

    Task AggiornaStatoAsync(
        CampionaturaStatoUpdateModel campionatura,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaCorrezioneStatoListItem>> GetCorrezioniStatoAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaRilievoListItem>> GetRilieviAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default);

    Task<CampionaturaRilievoDettaglio?> GetRilievoAsync(
        int idRilievoCampionatura,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaTipoProblematicaLookupItem>> GetTipiProblematicheAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaProblematicaStandardLookupItem>> GetProblematicheStandardAsync(
        CancellationToken cancellationToken = default);

    Task<int> CreaRilievoAsync(
        CampionaturaRilievoCreateModel rilievo,
        CancellationToken cancellationToken = default);

    Task AggiornaStatoRilievoAsync(
        CampionaturaRilievoStatoUpdateModel rilievo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaRilievoCorrezioneStatoListItem>> GetCorrezioniStatoRilievoAsync(
        int idRilievoCampionatura,
        CancellationToken cancellationToken = default);

    Task AggiornaRilievoAsync(
        CampionaturaRilievoUpdateModel rilievo,
        CancellationToken cancellationToken = default);

    Task EliminaRilievoAsync(
        CampionaturaRilievoDeleteModel rilievo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CampionaturaAdeguamentoListItem>> GetAdeguamentiAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default);

    Task<int> CreaAdeguamentoAsync(
        CampionaturaAdeguamentoCreateModel adeguamento,
        CancellationToken cancellationToken = default);

    Task<CampionaturaAdeguamentoDettaglio?> GetAdeguamentoAsync(
        int idAdeguamento,
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

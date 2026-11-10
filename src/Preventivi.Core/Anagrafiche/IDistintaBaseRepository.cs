namespace Preventivi.Core.Anagrafiche;

public interface IDistintaBaseRepository
{
    Task<IReadOnlyList<DistintaArticoloListItem>> GetArticoliAsync(string? ricerca = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TipoNodoDistintaLookupItem>> GetTipiNodoAsync(int? idCorrente = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DistintaNodoItem>> GetNodiAsync(int idArticolo, CancellationToken cancellationToken = default);
    Task<DistintaNodoDettaglio?> GetNodoAsync(int idNodoDistinta, CancellationToken cancellationToken = default);
    Task<int> CreaNodoAsync(DistintaNodoCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaNodoAsync(DistintaNodoUpdateModel modello, CancellationToken cancellationToken = default);
    Task ImpostaStatoNodoAsync(DistintaNodoStatoModel modello, CancellationToken cancellationToken = default);
    Task EliminaNodoAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DistintaMaterialeLookupItem>> GetMaterialiLookupAsync(int? idCorrente = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DistintaMaterialeDettaglio>> GetMaterialiAsync(int idNodoDistinta, CancellationToken cancellationToken = default);
    Task<DistintaMaterialeDettaglio?> GetMaterialeAsync(int idDistintaMateriale, CancellationToken cancellationToken = default);
    Task<int> CreaMaterialeAsync(DistintaMaterialeCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaMaterialeAsync(DistintaMaterialeUpdateModel modello, CancellationToken cancellationToken = default);
    Task EliminaMaterialeAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DistintaLavorazioneLookupItem>> GetLavorazioniLookupAsync(int? idCorrente = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DistintaLavorazioneDettaglio>> GetLavorazioniAsync(int idNodoDistinta, CancellationToken cancellationToken = default);
    Task<DistintaLavorazioneDettaglio?> GetLavorazioneAsync(int idDistintaLavorazione, CancellationToken cancellationToken = default);
    Task<int> CreaLavorazioneAsync(DistintaLavorazioneCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaLavorazioneAsync(DistintaLavorazioneUpdateModel modello, CancellationToken cancellationToken = default);
    Task EliminaLavorazioneAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default);
}

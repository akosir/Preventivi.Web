namespace Preventivi.Core.Anagrafiche;

public interface IArticoloRepository
{
    Task<IReadOnlyList<ClienteAnagraficaLookupItem>> GetClientiAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ArticoloListItem>> GetElencoAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        int? idCliente = null,
        CancellationToken cancellationToken = default);
    Task<ArticoloDettaglio?> GetDettaglioAsync(
        int idArticolo,
        CancellationToken cancellationToken = default);
    Task<int> CreaAsync(
        ArticoloCreateModel modello,
        CancellationToken cancellationToken = default);
    Task AggiornaAsync(
        ArticoloUpdateModel modello,
        CancellationToken cancellationToken = default);
    Task ImpostaStatoAsync(
        AnagraficaProduttivaStatoModel modello,
        CancellationToken cancellationToken = default);
    Task EliminaAsync(
        AnagraficaProduttivaDeleteModel modello,
        CancellationToken cancellationToken = default);
}

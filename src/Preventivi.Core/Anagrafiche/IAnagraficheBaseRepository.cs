namespace Preventivi.Core.Anagrafiche;

public interface IAnagraficheBaseRepository
{
    Task<IReadOnlyList<AnagraficaBaseListItem>> GetElencoAsync(
        TipoAnagraficaBase tipo,
        string? ricerca = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default);

    Task<AnagraficaBaseDettaglio?> GetDettaglioAsync(
        TipoAnagraficaBase tipo,
        int id,
        CancellationToken cancellationToken = default);

    Task<int> CreaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseCreateModel modello,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseUpdateModel modello,
        CancellationToken cancellationToken = default);

    Task ImpostaStatoAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseStatoModel modello,
        CancellationToken cancellationToken = default);

    Task EliminaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseDeleteModel modello,
        CancellationToken cancellationToken = default);
}

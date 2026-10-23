namespace Preventivi.Core.Preventivi;

public interface IModelloPreventivoRepository
{
    Task<IReadOnlyList<ModelloPreventivoListItem>> GetElencoAsync(
        string? ricerca = null,
        int? idCliente = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default);

    Task<ModelloPreventivoDettaglio?> GetDettaglioAsync(
        int idModelloPreventivo,
        CancellationToken cancellationToken = default);

    Task<int> CreaAsync(
        ModelloPreventivoCreateModel modello,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        ModelloPreventivoUpdateModel modello,
        CancellationToken cancellationToken = default);

    Task ImpostaAttivoAsync(
        int idModelloPreventivo,
        bool attivo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ModelloPreventivoRigaItem>> GetRigheAsync(
        int idModelloPreventivo,
        CancellationToken cancellationToken = default);

    Task<ModelloPreventivoRigaItem?> GetRigaAsync(
        int idRigaModelloPreventivo,
        CancellationToken cancellationToken = default);

    Task<int> CreaRigaAsync(
        ModelloPreventivoRigaCreateModel riga,
        CancellationToken cancellationToken = default);

    Task AggiornaRigaAsync(
        ModelloPreventivoRigaUpdateModel riga,
        CancellationToken cancellationToken = default);

    Task EliminaRigaAsync(
        int idRigaModelloPreventivo,
        CancellationToken cancellationToken = default);
}

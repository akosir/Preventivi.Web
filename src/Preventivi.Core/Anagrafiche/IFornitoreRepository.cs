namespace Preventivi.Core.Anagrafiche;

public interface IFornitoreRepository
{
    Task<IReadOnlyList<FornitoreDettaglio>> GetElencoAsync(string? ricerca = null,
        bool? soloAttivi = null, CancellationToken cancellationToken = default);
    Task<FornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<FornitoreDipendenza>> GetDipendenzeAsync(int id, CancellationToken cancellationToken = default);
    Task<int> CreaAsync(FornitoreCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaAsync(FornitoreUpdateModel modello, CancellationToken cancellationToken = default);
    Task ImpostaStatoAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default);
    Task EliminaAsync(int id, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default);
}

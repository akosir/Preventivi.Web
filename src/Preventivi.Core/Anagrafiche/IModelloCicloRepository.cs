namespace Preventivi.Core.Anagrafiche;

public interface IModelloCicloRepository
{
    Task<IReadOnlyList<ModelloCicloListItem>> GetElencoAsync(string? ricerca = null, bool? soloAttivi = null, CancellationToken cancellationToken = default);
    Task<ModelloCicloDettaglio?> GetDettaglioAsync(int idModelloCiclo, CancellationToken cancellationToken = default);
    Task<int> CreaAsync(ModelloCicloCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaAsync(ModelloCicloUpdateModel modello, CancellationToken cancellationToken = default);
    Task ImpostaStatoAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default);
    Task EliminaAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ModelloCicloRigaListItem>> GetRigheAsync(int idModelloCiclo, CancellationToken cancellationToken = default);
    Task<ModelloCicloRigaDettaglio?> GetRigaAsync(int idRigaModelloCiclo, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<ModelloCicloLavorazioneLookupItem>> GetLavorazioniAsync(int? idCorrente = null, CancellationToken cancellationToken = default);
    Task<int> CreaRigaAsync(ModelloCicloRigaCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaRigaAsync(ModelloCicloRigaUpdateModel modello, CancellationToken cancellationToken = default);
    Task EliminaRigaAsync(ModelloCicloRigaDeleteModel modello, CancellationToken cancellationToken = default);
}

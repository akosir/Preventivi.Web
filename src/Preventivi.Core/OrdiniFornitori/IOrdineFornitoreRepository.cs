namespace Preventivi.Core.OrdiniFornitori;

public interface IOrdineFornitoreRepository
{
    Task<IReadOnlyList<OrdineFornitoreDettaglio>> GetElencoAsync(OrdineFornitoreFiltro filtro, CancellationToken cancellationToken = default);
    Task<OrdineFornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrdineFornitoreRiga>> GetRigheAsync(int idOrdine, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrdineFornitoreDipendenza>> GetDipendenzeAsync(int idOrdine, int? idRiga = null, CancellationToken cancellationToken = default);
    Task<int> SalvaAsync(int? id, OrdineFornitoreSalvataggio modello, CancellationToken cancellationToken = default);
    Task<int> SalvaRigaAsync(int idOrdine, int? idRiga, OrdineFornitoreRigaSalvataggio modello, CancellationToken cancellationToken = default);
    Task EliminaAsync(int id, byte[] versione, string utente, CancellationToken cancellationToken = default);
    Task EliminaRigaAsync(int idOrdine, int idRiga, byte[] versioneOrdine, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default);
}

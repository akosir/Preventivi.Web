using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Data.Comune;

namespace Preventivi.Data.OrdiniFornitori;

public sealed class OrdineFornitoreRepository(DatabaseExecutor db) : IOrdineFornitoreRepository
{
    public Task<IReadOnlyList<OrdineFornitoreDettaglio>> GetElencoAsync(OrdineFornitoreFiltro filtro, CancellationToken cancellationToken = default) =>
        db.QueryAsync<OrdineFornitoreDettaglio>("dbo.OrdiniFornitori_Elenco",
            [Numero("@Numero", filtro.Numero), Numero("@Anno", filtro.Anno), Numero("@IdFornitore", filtro.IdFornitore),
             Data("@Dal", filtro.Dal), Data("@Al", filtro.Al), Testo("@Stato", filtro.Stato, 30), Testo("@Oggetto", filtro.Oggetto, 250)],
            cancellationToken);

    public Task<OrdineFornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default) =>
        db.QuerySingleAsync<OrdineFornitoreDettaglio>("dbo.OrdiniFornitori_Dettaglio", [Numero("@IdOrdine", id)], cancellationToken);

    public Task<IReadOnlyList<OrdineFornitoreRiga>> GetRigheAsync(int idOrdine, CancellationToken cancellationToken = default) =>
        db.QueryAsync<OrdineFornitoreRiga>("dbo.OrdiniFornitori_Righe_Elenco", [Numero("@IdOrdine", idOrdine)], cancellationToken);

    public Task<IReadOnlyList<OrdineFornitoreDipendenza>> GetDipendenzeAsync(int idOrdine, int? idRiga = null, CancellationToken cancellationToken = default) =>
        db.QueryAsync<OrdineFornitoreDipendenza>("dbo.OrdiniFornitori_Dipendenze",
            [Numero("@IdOrdine", idOrdine), Numero("@IdRiga", idRiga)], cancellationToken);

    public Task<int> SalvaAsync(int? id, OrdineFornitoreSalvataggio modello, CancellationToken cancellationToken = default) =>
        db.ExecuteScalarAsync<int>("dbo.OrdiniFornitori_Salva",
            [Numero("@IdOrdine", id), Data("@DataOrdine", modello.DataOrdine), Numero("@IdFornitore", modello.IdFornitore),
             Testo("@Oggetto", modello.Oggetto, 250), Testo("@Note", modello.Note, -1),
             Data("@DataConsegnaPrevista", modello.DataConsegnaPrevista), Testo("@Utente", modello.Utente, 256),
             Versione("@VersioneRiga", modello.VersioneRiga)], cancellationToken);

    public Task<int> SalvaRigaAsync(int idOrdine, int? idRiga, OrdineFornitoreRigaSalvataggio modello, CancellationToken cancellationToken = default) =>
        db.ExecuteScalarAsync<int>("dbo.OrdiniFornitori_Righe_Salva",
            [Numero("@IdOrdine", idOrdine), Numero("@IdRiga", idRiga), Numero("@RigaNr", modello.RigaNr),
             Testo("@TipoRiga", modello.TipoRiga, 20), Numero("@IdMateriale", modello.IdMateriale),
             Numero("@IdLavorazione", modello.IdLavorazione), Testo("@Descrizione", modello.Descrizione, 250),
             Testo("@UM", modello.UM, 10), Decimale("@Quantita", modello.Quantita),
             Decimale("@PrezzoUnitario", modello.PrezzoUnitario), Data("@DataConsegnaPrevista", modello.DataConsegnaPrevista),
             Testo("@Note", modello.Note, 500), Testo("@Utente", modello.Utente, 256),
             Versione("@VersioneRiga", modello.VersioneRiga), Versione("@VersioneOrdine", modello.VersioneOrdine)], cancellationToken);

    public async Task EliminaAsync(int id, byte[] versione, string utente, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.OrdiniFornitori_Elimina",
            [Numero("@IdOrdine", id), Versione("@VersioneOrdine", versione), Testo("@Utente", utente, 256)], cancellationToken);

    public async Task EliminaRigaAsync(int idOrdine, int idRiga, byte[] versioneOrdine, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.OrdiniFornitori_Righe_Elimina",
            [Numero("@IdOrdine", idOrdine), Numero("@IdRiga", idRiga), Versione("@VersioneOrdine", versioneOrdine),
             Versione("@VersioneRiga", versioneRiga), Testo("@Utente", utente, 256)], cancellationToken);

    private static SqlParameter Numero(string nome, int? valore) => new(nome, SqlDbType.Int) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter Data(string nome, DateTime? valore) => new(nome, SqlDbType.Date) { Value = (object?)valore?.Date ?? DBNull.Value };
    private static SqlParameter Testo(string nome, string? valore, int lunghezza) =>
        new(nome, SqlDbType.NVarChar, lunghezza) { Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim() };
    private static SqlParameter Versione(string nome, byte[] valore) =>
        new(nome, SqlDbType.Timestamp, 8) { Value = valore.Length == 0 ? DBNull.Value : valore };
    private static SqlParameter Decimale(string nome, decimal valore) =>
        new(nome, SqlDbType.Decimal) { Precision = 18, Scale = 4, Value = valore };
}

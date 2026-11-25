using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Sicurezza;

public sealed class GestioneUtentiRepository(DatabaseExecutor db) : IGestioneUtentiRepository
{
    public Task<IReadOnlyList<UtenteGestione>> GetElencoAsync(AmministratoreOperante attore, string? ricerca, bool? attivo, CancellationToken cancellationToken = default) =>
        db.QueryAsync<UtenteGestione>("dbo.Utenti_Gestione_Elenco", [..Attore(attore), Testo("@Ricerca",ricerca,150), new("@Attivo",SqlDbType.Bit) { Value=(object?)attivo ?? DBNull.Value }],cancellationToken);
    public Task<UtenteGestione?> GetDettaglioAsync(AmministratoreOperante attore,int id,CancellationToken cancellationToken=default) =>
        db.QuerySingleAsync<UtenteGestione>("dbo.Utenti_Gestione_Dettaglio",[..Attore(attore),Numero("@IdUtente",id)],cancellationToken);
    public Task<IReadOnlyList<RuoloGestione>> GetRuoliAsync(AmministratoreOperante attore,CancellationToken cancellationToken=default) =>
        db.QueryAsync<RuoloGestione>("dbo.Utenti_Gestione_Ruoli",Attore(attore),cancellationToken);
    public Task<IReadOnlyList<UtenteAudit>> GetAuditAsync(AmministratoreOperante attore,int id,CancellationToken cancellationToken=default) =>
        db.QueryAsync<UtenteAudit>("dbo.Utenti_Gestione_Audit",[..Attore(attore),Numero("@IdUtente",id)],cancellationToken);
    public Task<int> SalvaAsync(AmministratoreOperante attore,int? id,UtenteSalvataggio dati,string? passwordHash,CancellationToken cancellationToken=default) =>
        db.ExecuteScalarAsync<int>("dbo.Utenti_Gestione_Salva",[..Attore(attore),Numero("@IdUtente",id),
            Testo("@Username",dati.Username,50),Testo("@NomeCompleto",dati.NomeCompleto,150),
            new("@Attivo",SqlDbType.Bit) { Value=dati.Attivo }, Testo("@RuoliJson",JsonSerializer.Serialize(dati.Ruoli),-1),
            Versione(dati.VersioneRiga),Testo("@PasswordHash",passwordHash,255)],cancellationToken);
    public async Task ReimpostaPasswordAsync(AmministratoreOperante attore,int id,byte[] versione,string passwordHash,CancellationToken cancellationToken=default) =>
        await db.ExecuteAsync("dbo.Utenti_Gestione_Password",[..Attore(attore),Numero("@IdUtente",id),Versione(versione),Testo("@PasswordHash",passwordHash,255)],cancellationToken);
    private static SqlParameter[] Attore(AmministratoreOperante attore) =>
        [Numero("@IdOperatore",attore.IdUtente),new("@SessioneOperatore",SqlDbType.UniqueIdentifier) { Value=attore.VersioneSessione }];
    private static SqlParameter Numero(string nome,int? valore) => new(nome,SqlDbType.Int) { Value=(object?)valore ?? DBNull.Value };
    private static SqlParameter Testo(string nome,string? valore,int lunghezza) => new(nome,SqlDbType.NVarChar,lunghezza) { Value=(object?)valore ?? DBNull.Value };
    private static SqlParameter Versione(byte[] valore) => new("@VersioneRiga",SqlDbType.Binary,8) { Value=valore.Length==8 ? valore : DBNull.Value };
}

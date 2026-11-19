using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class ModelloCicloRepository(DatabaseExecutor db) : IModelloCicloRepository
{
    public Task<IReadOnlyList<ModelloCicloListItem>> GetElencoAsync(string? ricerca = null, bool? soloAttivi = null, CancellationToken cancellationToken = default) =>
        db.QueryAsync<ModelloCicloListItem>("dbo.Anagrafiche_ModelliCiclo_Elenco", [NullableText("@Ricerca", ricerca, 200), NullableBit("@SoloAttivi", soloAttivi)], cancellationToken);

    public Task<ModelloCicloDettaglio?> GetDettaglioAsync(int idModelloCiclo, CancellationToken cancellationToken = default) =>
        db.QuerySingleAsync<ModelloCicloDettaglio>("dbo.Anagrafiche_ModelliCiclo_Dettaglio", [new SqlParameter("@IdModelloCiclo", idModelloCiclo)], cancellationToken);

    public Task<int> CreaAsync(ModelloCicloCreateModel modello, CancellationToken cancellationToken = default) =>
        db.ExecuteScalarAsync<int>("dbo.Anagrafiche_ModelliCiclo_Crea", Parametri(modello), cancellationToken);

    public async Task AggiornaAsync(ModelloCicloUpdateModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_ModelliCiclo_Aggiorna", [new SqlParameter("@IdModelloCiclo", modello.IdModelloCiclo), .. Parametri(modello), RowVersion(modello.VersioneRiga)], cancellationToken);

    public async Task ImpostaStatoAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_ModelliCiclo_ImpostaStato", [new SqlParameter("@IdModelloCiclo", modello.Id), new SqlParameter("@Attivo", SqlDbType.Bit) { Value = modello.Attivo }, Text("@Utente", modello.Utente, 256), RowVersion(modello.VersioneRiga)], cancellationToken);

    public async Task EliminaAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_ModelliCiclo_Elimina", [new SqlParameter("@IdModelloCiclo", modello.Id), RowVersion(modello.VersioneRiga)], cancellationToken);

    public Task<IReadOnlyList<ModelloCicloRigaListItem>> GetRigheAsync(int idModelloCiclo, CancellationToken cancellationToken = default) =>
        db.QueryAsync<ModelloCicloRigaListItem>("dbo.Anagrafiche_ModelliCiclo_Righe_Elenco", [new SqlParameter("@IdModelloCiclo", idModelloCiclo)], cancellationToken);

    public Task<ModelloCicloRigaDettaglio?> GetRigaAsync(int idRigaModelloCiclo, CancellationToken cancellationToken = default) =>
        db.QuerySingleAsync<ModelloCicloRigaDettaglio>("dbo.Anagrafiche_ModelliCiclo_Righe_Dettaglio", [new SqlParameter("@IdRigaModelloCiclo", idRigaModelloCiclo)], cancellationToken);

    public Task<IReadOnlyList<ModelloCicloLavorazioneLookupItem>> GetLavorazioniAsync(int? idCorrente = null, CancellationToken cancellationToken = default) =>
        db.QueryAsync<ModelloCicloLavorazioneLookupItem>("dbo.Anagrafiche_ModelliCiclo_Lavorazioni_Lookup", [NullableInt("@IdCorrente", idCorrente)], cancellationToken);

    public Task<int> CreaRigaAsync(ModelloCicloRigaCreateModel modello, CancellationToken cancellationToken = default) =>
        db.ExecuteScalarAsync<int>("dbo.Anagrafiche_ModelliCiclo_Righe_Crea", ParametriRiga(modello), cancellationToken);

    public async Task AggiornaRigaAsync(ModelloCicloRigaUpdateModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_ModelliCiclo_Righe_Aggiorna", [new SqlParameter("@IdRigaModelloCiclo", modello.IdRigaModelloCiclo), .. ParametriRiga(modello), RowVersion(modello.VersioneRiga)], cancellationToken);

    public async Task EliminaRigaAsync(ModelloCicloRigaDeleteModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_ModelliCiclo_Righe_Elimina", [new SqlParameter("@IdRigaModelloCiclo", modello.IdRigaModelloCiclo), new SqlParameter("@IdModelloCiclo", modello.IdModelloCiclo), RowVersion(modello.VersioneRiga)], cancellationToken);

    private static IEnumerable<SqlParameter> Parametri(ModelloCicloCreateModel modello) =>
    [
        Text("@CodiceModelloCiclo", modello.CodiceModelloCiclo, 50),
        Text("@Descrizione", modello.Descrizione, 150),
        NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static IEnumerable<SqlParameter> ParametriRiga(ModelloCicloRigaCreateModel modello) =>
    [
        new SqlParameter("@IdModelloCiclo", modello.IdModelloCiclo),
        new SqlParameter("@RigaNr", modello.RigaNr),
        new SqlParameter("@Sequenza", modello.Sequenza),
        new SqlParameter("@IdLavorazione", modello.IdLavorazione),
        Decimal("@TempoSetupMin", modello.TempoSetupMin, 18, 2),
        Decimal("@TempoPezzoMin", modello.TempoPezzoMin, 18, 4),
        Decimal("@CostoOrario", modello.CostoOrario, 18, 4),
        Decimal("@CostoFisso", modello.CostoFisso, 18, 4),
        NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static SqlParameter Text(string nome, string valore, int dimensione) => new(nome, SqlDbType.NVarChar, dimensione) { Value = valore.Trim() };
    private static SqlParameter NullableText(string nome, string? valore, int dimensione) => new(nome, SqlDbType.NVarChar, dimensione) { Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim() };
    private static SqlParameter NullableInt(string nome, int? valore) => new(nome, SqlDbType.Int) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter NullableBit(string nome, bool? valore) => new(nome, SqlDbType.Bit) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter Decimal(string nome, decimal valore, byte precisione, byte scala) => new(nome, SqlDbType.Decimal) { Precision = precisione, Scale = scala, Value = valore };
    private static SqlParameter RowVersion(byte[] valore) => new("@VersioneRiga", SqlDbType.Timestamp, 8) { Value = valore };
}

using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.Preventivi;

public sealed class ModelloPreventivoRepository : IModelloPreventivoRepository
{
    private readonly DatabaseExecutor _db;

    public ModelloPreventivoRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<ModelloPreventivoListItem>> GetElencoAsync(
        string? ricerca = null,
        int? idCliente = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<ModelloPreventivoListItem>(
            "dbo.Preventivi_Modelli_Elenco",
            [
                NullableText("@Ricerca", ricerca, 300),
                NullableInt("@IdCliente", idCliente),
                NullableBit("@SoloAttivi", soloAttivi)
            ],
            cancellationToken);
    }

    public async Task<ModelloPreventivoDettaglio?> GetDettaglioAsync(
        int idModelloPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<ModelloPreventivoDettaglio>(
            "dbo.Preventivi_Modelli_Dettaglio",
            [new SqlParameter("@IdModelloPreventivo", idModelloPreventivo)],
            cancellationToken);
    }

    public async Task<int> CreaAsync(
        ModelloPreventivoCreateModel modello,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Modelli_Crea",
            [
                Text("@CodiceModelloPreventivo", modello.CodiceModelloPreventivo, 50),
                Text("@Descrizione", modello.Descrizione, 150),
                NullableInt("@IdCliente", modello.IdCliente),
                NullableText("@Oggetto", modello.Oggetto, 250),
                NullableText("@Note", modello.Note)
            ],
            cancellationToken);
    }

    public async Task AggiornaAsync(
        ModelloPreventivoUpdateModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Modelli_Aggiorna",
            [
                new SqlParameter("@IdModelloPreventivo", modello.IdModelloPreventivo),
                Text("@CodiceModelloPreventivo", modello.CodiceModelloPreventivo, 50),
                Text("@Descrizione", modello.Descrizione, 150),
                NullableInt("@IdCliente", modello.IdCliente),
                NullableText("@Oggetto", modello.Oggetto, 250),
                NullableText("@Note", modello.Note)
            ],
            cancellationToken);
    }

    public async Task ImpostaAttivoAsync(
        int idModelloPreventivo,
        bool attivo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Modelli_ImpostaAttivo",
            [
                new SqlParameter("@IdModelloPreventivo", idModelloPreventivo),
                new SqlParameter("@Attivo", SqlDbType.Bit) { Value = attivo }
            ],
            cancellationToken);
    }

    public async Task<IReadOnlyList<ModelloPreventivoRigaItem>> GetRigheAsync(
        int idModelloPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<ModelloPreventivoRigaItem>(
            "dbo.Preventivi_Modelli_Righe_Elenco",
            [new SqlParameter("@IdModelloPreventivo", idModelloPreventivo)],
            cancellationToken);
    }

    public async Task<ModelloPreventivoRigaItem?> GetRigaAsync(
        int idRigaModelloPreventivo,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<ModelloPreventivoRigaItem>(
            "dbo.Preventivi_Modelli_Righe_Dettaglio",
            [new SqlParameter("@IdRigaModelloPreventivo", idRigaModelloPreventivo)],
            cancellationToken);
    }

    public async Task<int> CreaRigaAsync(
        ModelloPreventivoRigaCreateModel riga,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Preventivi_Modelli_Righe_Crea",
            ParametriRiga(
                riga.IdModelloPreventivo,
                null,
                riga.RigaNr,
                riga.IdTipoRiga,
                riga.IdArticolo,
                riga.IdModelloCiclo,
                riga.DescrizioneVoce,
                riga.Quantita,
                riga.PrezzoUnitarioVendita,
                riga.Note),
            cancellationToken);
    }

    public async Task AggiornaRigaAsync(
        ModelloPreventivoRigaUpdateModel riga,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Modelli_Righe_Aggiorna",
            ParametriRiga(
                null,
                riga.IdRigaModelloPreventivo,
                riga.RigaNr,
                riga.IdTipoRiga,
                riga.IdArticolo,
                riga.IdModelloCiclo,
                riga.DescrizioneVoce,
                riga.Quantita,
                riga.PrezzoUnitarioVendita,
                riga.Note),
            cancellationToken);
    }

    public async Task EliminaRigaAsync(
        int idRigaModelloPreventivo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Preventivi_Modelli_Righe_Elimina",
            [new SqlParameter("@IdRigaModelloPreventivo", idRigaModelloPreventivo)],
            cancellationToken);
    }

    private static SqlParameter[] ParametriRiga(
        int? idModelloPreventivo,
        int? idRigaModelloPreventivo,
        int rigaNr,
        int idTipoRiga,
        int? idArticolo,
        int? idModelloCiclo,
        string descrizioneVoce,
        decimal quantita,
        decimal prezzoUnitarioVendita,
        string? note)
    {
        var parameters = new List<SqlParameter>();

        if (idModelloPreventivo.HasValue)
            parameters.Add(new SqlParameter("@IdModelloPreventivo", idModelloPreventivo.Value));
        if (idRigaModelloPreventivo.HasValue)
            parameters.Add(new SqlParameter("@IdRigaModelloPreventivo", idRigaModelloPreventivo.Value));

        parameters.AddRange(
        [
            new SqlParameter("@RigaNr", rigaNr),
            new SqlParameter("@IdTipoRiga", idTipoRiga),
            NullableInt("@IdArticolo", idArticolo),
            NullableInt("@IdModelloCiclo", idModelloCiclo),
            Text("@DescrizioneVoce", descrizioneVoce, 250),
            Decimal("@Quantita", quantita),
            Decimal("@PrezzoUnitarioVendita", prezzoUnitarioVendita),
            NullableText("@Note", note)
        ]);

        return parameters.ToArray();
    }

    private static SqlParameter Text(string name, string value, int length) =>
        new(name, SqlDbType.NVarChar, length) { Value = value.Trim() };

    private static SqlParameter NullableText(string name, string? value, int length = -1) =>
        new(name, SqlDbType.NVarChar, length)
        {
            Value = string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim()
        };

    private static SqlParameter NullableInt(string name, int? value) =>
        new(name, SqlDbType.Int) { Value = value.HasValue ? value.Value : DBNull.Value };

    private static SqlParameter NullableBit(string name, bool? value) =>
        new(name, SqlDbType.Bit) { Value = value.HasValue ? value.Value : DBNull.Value };

    private static SqlParameter Decimal(string name, decimal value) =>
        new(name, SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 4,
            Value = value
        };
}

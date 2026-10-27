using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Campionature;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Campionature;

public sealed class CampionaturaRepository : ICampionaturaRepository
{
    private readonly DatabaseExecutor _db;

    public CampionaturaRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<CampionaturaListItem>> GetElencoAsync(
        CampionaturaFiltro filtro,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaListItem>(
            "dbo.Campionature_Elenco",
            [
                NullableText("@Ricerca", filtro.Ricerca, 300),
                NullableInt("@IdCliente", filtro.IdCliente),
                NullableInt("@IdRichiestaCliente", filtro.IdRichiestaCliente),
                NullableText("@Stato", filtro.Stato, 30),
                NullableText("@Priorita", filtro.Priorita, 20),
                NullableDate("@ConsegnaDa", filtro.ConsegnaDa),
                NullableDate("@ConsegnaA", filtro.ConsegnaA)
            ],
            cancellationToken);
    }

    public async Task<CampionaturaDettaglio?> GetDettaglioAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<CampionaturaDettaglio>(
            "dbo.Campionature_Dettaglio",
            [new SqlParameter("@IdCampionatura", idCampionatura)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaRichiestaLookupItem>> GetRichiesteAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaRichiestaLookupItem>(
            "dbo.Campionature_Richieste_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaPreventivoLookupItem>> GetPreventiviAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaPreventivoLookupItem>(
            "dbo.Campionature_Preventivi_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaVarianteLookupItem>> GetVariantiAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaVarianteLookupItem>(
            "dbo.Campionature_Varianti_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<int> CreaAsync(
        CampionaturaCreateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Campionature_Crea",
            ParametriDati(campionatura),
            cancellationToken);
    }

    public async Task AggiornaAsync(
        CampionaturaUpdateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Aggiorna",
            [
                new SqlParameter("@IdCampionatura", campionatura.IdCampionatura),
                .. ParametriDati(campionatura),
                RowVersion("@VersioneRiga", campionatura.VersioneRiga)
            ],
            cancellationToken);
    }

    private static SqlParameter[] ParametriDati(CampionaturaCreateModel campionatura) =>
    [
        Date("@DataCampionatura", campionatura.DataCampionatura),
        new SqlParameter("@IdRichiestaCliente", campionatura.IdRichiestaCliente),
        NullableInt("@IdPreventivo", campionatura.IdPreventivo),
        NullableInt("@IdVariantePreventivo", campionatura.IdVariantePreventivo),
        Text("@Oggetto", campionatura.Oggetto, 250),
        NullableText("@DescrizioneCampione", campionatura.DescrizioneCampione),
        Text("@Stato", campionatura.Stato, 30),
        Text("@Priorita", campionatura.Priorita, 20),
        NullableDate("@DataRichiestaCampione", campionatura.DataRichiestaCampione),
        NullableDate("@DataPrevistaConsegna", campionatura.DataPrevistaConsegna),
        NullableDate("@DataConsegnaCampione", campionatura.DataConsegnaCampione),
        NullableDate("@DataChiusura", campionatura.DataChiusura),
        NullableText("@Esito", campionatura.Esito, 30),
        NullableText("@Note", campionatura.Note),
        Text("@Utente", campionatura.Utente, 256)
    ];

    private static SqlParameter Text(string name, string value, int length) =>
        new(name, SqlDbType.NVarChar, length) { Value = value.Trim() };

    private static SqlParameter NullableText(string name, string? value, int length = -1) =>
        new(name, SqlDbType.NVarChar, length)
        {
            Value = string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim()
        };

    private static SqlParameter NullableInt(string name, int? value) =>
        new(name, SqlDbType.Int) { Value = value.HasValue ? value.Value : DBNull.Value };

    private static SqlParameter Date(string name, DateOnly value) =>
        new(name, SqlDbType.Date) { Value = value.ToDateTime(TimeOnly.MinValue) };

    private static SqlParameter NullableDate(string name, DateOnly? value) =>
        new(name, SqlDbType.Date)
        {
            Value = value.HasValue
                ? value.Value.ToDateTime(TimeOnly.MinValue)
                : DBNull.Value
        };

    private static SqlParameter RowVersion(string name, byte[] value) =>
        new(name, SqlDbType.Timestamp, 8) { Value = value };
}

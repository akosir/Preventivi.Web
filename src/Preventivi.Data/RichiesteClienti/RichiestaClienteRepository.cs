using Microsoft.Data.SqlClient;
using Preventivi.Core.RichiesteClienti;
using Preventivi.Core.Preventivi;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.RichiesteClienti;

public sealed class RichiestaClienteRepository : IRichiestaClienteRepository
{
    private readonly DatabaseExecutor _db;

    public RichiestaClienteRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<RichiestaClienteListItem>> GetElencoAsync(
        RichiestaClienteFiltro filtro,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<RichiestaClienteListItem>(
            "dbo.RichiesteClienti_Elenco",
            [
                NullableText("@Ricerca", filtro.Ricerca, 300),
                NullableInt("@IdCliente", filtro.IdCliente),
                NullableText("@Stato", filtro.Stato, 30),
                NullableText("@Priorita", filtro.Priorita, 20),
                NullableText("@InteresseCliente", filtro.InteresseCliente, 20),
                NullableDate("@ScadenzaDa", filtro.ScadenzaDa),
                NullableDate("@ScadenzaA", filtro.ScadenzaA)
            ],
            cancellationToken);
    }

    public async Task<RichiestaClienteDettaglio?> GetDettaglioAsync(
        int idRichiestaCliente,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<RichiestaClienteDettaglio>(
            "dbo.RichiesteClienti_Dettaglio",
            [new SqlParameter("@IdRichiestaCliente", idRichiestaCliente)],
            cancellationToken);
    }

    public async Task<int> CreaAsync(
        RichiestaClienteCreateModel richiesta,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.RichiesteClienti_Crea",
            ParametriDati(
                richiesta.DataRichiesta,
                richiesta.IdCliente,
                richiesta.Oggetto,
                richiesta.DescrizioneRichiesta,
                richiesta.Stato,
                richiesta.Priorita,
                richiesta.InteresseCliente,
                richiesta.DataScadenza,
                richiesta.ProbabilitaChiusura,
                richiesta.Note,
                richiesta.Utente),
            cancellationToken);
    }

    public async Task AggiornaAsync(
        RichiestaClienteUpdateModel richiesta,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.RichiesteClienti_Aggiorna",
            [
                new SqlParameter("@IdRichiestaCliente", richiesta.IdRichiestaCliente),
                Date("@DataRichiesta", richiesta.DataRichiesta),
                new SqlParameter("@IdCliente", richiesta.IdCliente),
                Text("@Oggetto", richiesta.Oggetto, 250),
                NullableText("@DescrizioneRichiesta", richiesta.DescrizioneRichiesta),
                Text("@Stato", richiesta.Stato, 30),
                Text("@Priorita", richiesta.Priorita, 20),
                NullableText("@InteresseCliente", richiesta.InteresseCliente, 20),
                NullableDate("@DataScadenza", richiesta.DataScadenza),
                NullableInt("@ProbabilitaChiusura", richiesta.ProbabilitaChiusura),
                NullableText("@Note", richiesta.Note),
                Text("@Utente", richiesta.Utente, 256),
                RowVersion("@VersioneRiga", richiesta.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task AnnullaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.RichiesteClienti_Annulla",
            [
                new SqlParameter("@IdRichiestaCliente", idRichiestaCliente),
                RowVersion("@VersioneRiga", versioneRiga),
                Text("@Utente", utente, 256)
            ],
            cancellationToken);
    }

    public async Task RiattivaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.RichiesteClienti_Riattiva",
            [
                new SqlParameter("@IdRichiestaCliente", idRichiestaCliente),
                RowVersion("@VersioneRiga", versioneRiga),
                Text("@Utente", utente, 256)
            ],
            cancellationToken);
    }

    public async Task<int> CreaPreventivoAsync(
        PreventivoCreateModel preventivo,
        string utente,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.RichiesteClienti_Preventivo_Crea",
            [
                Text("@Origine", preventivo.Origine, 20),
                Date("@DataPreventivo", preventivo.DataPreventivo),
                NullableInt("@IdCliente", preventivo.IdCliente),
                NullableInt("@IdRichiestaCliente", preventivo.IdRichiestaCliente),
                NullableInt("@IdModelloPreventivo", preventivo.IdModelloPreventivo),
                Text("@Oggetto", preventivo.Oggetto, 250),
                NullableText("@Note", preventivo.Note),
                new SqlParameter("@MarkupPercDefault", SqlDbType.Decimal)
                {
                    Precision = 9,
                    Scale = 2,
                    Value = preventivo.MarkupPercDefault
                },
                Text("@Utente", utente, 256)
            ],
            cancellationToken);
    }

    public async Task<IReadOnlyList<RichiestaClientePreventivoItem>> GetPreventiviAsync(
        int idRichiestaCliente,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<RichiestaClientePreventivoItem>(
            "dbo.RichiesteClienti_Preventivi_Elenco",
            [new SqlParameter("@IdRichiestaCliente", idRichiestaCliente)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<RichiestaClienteCampionaturaItem>> GetCampionatureAsync(
        int idRichiestaCliente,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<RichiestaClienteCampionaturaItem>(
            "dbo.RichiesteClienti_Campionature_Elenco",
            [new SqlParameter("@IdRichiestaCliente", idRichiestaCliente)],
            cancellationToken);
    }

    private static SqlParameter[] ParametriDati(
        DateOnly dataRichiesta,
        int idCliente,
        string oggetto,
        string? descrizioneRichiesta,
        string stato,
        string priorita,
        string? interesseCliente,
        DateOnly? dataScadenza,
        int? probabilitaChiusura,
        string? note,
        string utente)
    {
        return
        [
            Date("@DataRichiesta", dataRichiesta),
            new SqlParameter("@IdCliente", idCliente),
            Text("@Oggetto", oggetto, 250),
            NullableText("@DescrizioneRichiesta", descrizioneRichiesta),
            Text("@Stato", stato, 30),
            Text("@Priorita", priorita, 20),
            NullableText("@InteresseCliente", interesseCliente, 20),
            NullableDate("@DataScadenza", dataScadenza),
            NullableInt("@ProbabilitaChiusura", probabilitaChiusura),
            NullableText("@Note", note),
            Text("@Utente", utente, 256)
        ];
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

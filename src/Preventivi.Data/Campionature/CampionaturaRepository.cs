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

    public async Task AggiornaStatoAsync(
        CampionaturaStatoUpdateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Stato_Aggiorna",
            [
                new SqlParameter("@IdCampionatura", campionatura.IdCampionatura),
                Text("@Stato", campionatura.Stato, 30),
                NullableDate("@DataConsegnaCampione", campionatura.DataConsegnaCampione),
                NullableText("@Esito", campionatura.Esito, 30),
                RowVersion("@VersioneRiga", campionatura.VersioneRiga),
                Text("@Utente", campionatura.Utente, 256),
                new SqlParameter("@Amministratore", campionatura.Amministratore),
                NullableText("@MotivazioneCorrezione", campionatura.MotivazioneCorrezione, 500)
            ],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaCorrezioneStatoListItem>> GetCorrezioniStatoAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaCorrezioneStatoListItem>(
            "dbo.Campionature_CorrezioniStato_Elenco",
            [new SqlParameter("@IdCampionatura", idCampionatura)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaRilievoListItem>> GetRilieviAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaRilievoListItem>(
            "dbo.Campionature_Rilievi_Elenco",
            [new SqlParameter("@IdCampionatura", idCampionatura)],
            cancellationToken);
    }

    public async Task<CampionaturaRilievoDettaglio?> GetRilievoAsync(
        int idRilievoCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<CampionaturaRilievoDettaglio>(
            "dbo.Campionature_Rilievi_Dettaglio",
            [new SqlParameter("@IdRilievoCampionatura", idRilievoCampionatura)],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaTipoProblematicaLookupItem>> GetTipiProblematicheAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaTipoProblematicaLookupItem>(
            "dbo.Campionature_Rilievi_Tipi_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaProblematicaStandardLookupItem>> GetProblematicheStandardAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaProblematicaStandardLookupItem>(
            "dbo.Campionature_Rilievi_Problematiche_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<int> CreaRilievoAsync(
        CampionaturaRilievoCreateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Campionature_Rilievi_Crea",
            [
                new SqlParameter("@IdCampionatura", rilievo.IdCampionatura),
                Date("@DataRilevazione", rilievo.DataRilevazione),
                new SqlParameter("@IdTipoProblematica", rilievo.IdTipoProblematica),
                NullableInt("@IdProblematicaStandard", rilievo.IdProblematicaStandard),
                Text("@DescrizioneProblema", rilievo.DescrizioneProblema),
                Text("@Gravita", rilievo.Gravita, 20),
                NullableText("@CausaPresunta", rilievo.CausaPresunta),
                NullableText("@SoluzioneProposta", rilievo.SoluzioneProposta),
                new SqlParameter("@RichiedeNuovoCampione", rilievo.RichiedeNuovoCampione),
                NullableText("@NoteCliente", rilievo.NoteCliente),
                NullableText("@NoteInterne", rilievo.NoteInterne),
                Text("@Utente", rilievo.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task AggiornaStatoRilievoAsync(
        CampionaturaRilievoStatoUpdateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Rilievi_Stato_Aggiorna",
            [
                new SqlParameter("@IdRilievoCampionatura", rilievo.IdRilievoCampionatura),
                Text("@Stato", rilievo.Stato, 30),
                RowVersion("@VersioneRiga", rilievo.VersioneRiga),
                Text("@Utente", rilievo.Utente, 256),
                new SqlParameter("@Amministratore", rilievo.Amministratore),
                NullableText("@MotivazioneCorrezione", rilievo.MotivazioneCorrezione, 500)
            ],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaRilievoCorrezioneStatoListItem>> GetCorrezioniStatoRilievoAsync(
        int idRilievoCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaRilievoCorrezioneStatoListItem>(
            "dbo.Campionature_Rilievi_CorrezioniStato_Elenco",
            [new SqlParameter("@IdRilievoCampionatura", idRilievoCampionatura)],
            cancellationToken);
    }

    public async Task AggiornaRilievoAsync(
        CampionaturaRilievoUpdateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Rilievi_Aggiorna",
            [
                new SqlParameter("@IdRilievoCampionatura", rilievo.IdRilievoCampionatura),
                Date("@DataRilevazione", rilievo.DataRilevazione),
                new SqlParameter("@IdTipoProblematica", rilievo.IdTipoProblematica),
                NullableInt("@IdProblematicaStandard", rilievo.IdProblematicaStandard),
                Text("@DescrizioneProblema", rilievo.DescrizioneProblema),
                Text("@Gravita", rilievo.Gravita, 20),
                NullableText("@CausaPresunta", rilievo.CausaPresunta),
                NullableText("@SoluzioneProposta", rilievo.SoluzioneProposta),
                new SqlParameter("@RichiedeNuovoCampione", rilievo.RichiedeNuovoCampione),
                NullableText("@NoteCliente", rilievo.NoteCliente),
                NullableText("@NoteInterne", rilievo.NoteInterne),
                RowVersion("@VersioneRiga", rilievo.VersioneRiga),
                Text("@Utente", rilievo.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task EliminaRilievoAsync(
        CampionaturaRilievoDeleteModel rilievo,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Rilievi_Elimina",
            [
                new SqlParameter("@IdRilievoCampionatura", rilievo.IdRilievoCampionatura),
                RowVersion("@VersioneRiga", rilievo.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task<IReadOnlyList<CampionaturaAdeguamentoListItem>> GetAdeguamentiAsync(
        int idCampionatura,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<CampionaturaAdeguamentoListItem>(
            "dbo.Campionature_Adeguamenti_Elenco",
            [new SqlParameter("@IdCampionatura", idCampionatura)],
            cancellationToken);
    }

    public async Task<int> CreaAdeguamentoAsync(
        CampionaturaAdeguamentoCreateModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Campionature_Adeguamenti_Crea",
            [
                new SqlParameter("@IdRilievoCampionatura", adeguamento.IdRilievoCampionatura),
                Text("@DescrizioneAdeguamento", adeguamento.DescrizioneAdeguamento),
                Decimal("@ImpattoCostoStimato", adeguamento.ImpattoCostoStimato),
                Decimal("@ImpattoVenditaStimato", adeguamento.ImpattoVenditaStimato),
                NullableText("@Note", adeguamento.Note),
                RowVersion("@VersioneRilievo", adeguamento.VersioneRilievo),
                Text("@Utente", adeguamento.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task<CampionaturaAdeguamentoDettaglio?> GetAdeguamentoAsync(
        int idAdeguamento,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<CampionaturaAdeguamentoDettaglio>(
            "dbo.Campionature_Adeguamenti_Dettaglio",
            [new SqlParameter("@IdAdeguamento", idAdeguamento)],
            cancellationToken);
    }

    public async Task AggiornaAdeguamentoAsync(
        CampionaturaAdeguamentoUpdateModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Adeguamenti_Aggiorna",
            [
                new SqlParameter("@IdAdeguamento", adeguamento.IdAdeguamento),
                Text("@DescrizioneAdeguamento", adeguamento.DescrizioneAdeguamento),
                Decimal("@ImpattoCostoStimato", adeguamento.ImpattoCostoStimato),
                Decimal("@ImpattoVenditaStimato", adeguamento.ImpattoVenditaStimato),
                NullableText("@Note", adeguamento.Note),
                RowVersion("@VersioneRiga", adeguamento.VersioneRiga),
                Text("@Utente", adeguamento.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task EliminaAdeguamentoAsync(
        CampionaturaAdeguamentoDeleteModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Adeguamenti_Elimina",
            [
                new SqlParameter("@IdAdeguamento", adeguamento.IdAdeguamento),
                RowVersion("@VersioneRiga", adeguamento.VersioneRiga),
                RowVersion("@VersioneRilievo", adeguamento.VersioneRilievo),
                Text("@Utente", adeguamento.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task<int> PreparaAdeguamentoAsync(
        CampionaturaAdeguamentoPreparaModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            "dbo.Campionature_Adeguamenti_PreparaVariante",
            [
                new SqlParameter("@IdAdeguamento", adeguamento.IdAdeguamento),
                Text("@CodiceVariante", adeguamento.CodiceVariante, 30),
                Text("@DescrizioneVariante", adeguamento.DescrizioneVariante, 250),
                RowVersion("@VersioneRiga", adeguamento.VersioneRiga),
                Text("@Utente", adeguamento.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task AnnullaPreparazioneAdeguamentoAsync(
        CampionaturaAdeguamentoAnnullaPreparazioneModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Adeguamenti_Preparazione_Annulla",
            [
                new SqlParameter("@IdAdeguamento", adeguamento.IdAdeguamento),
                RowVersion("@VersioneRiga", adeguamento.VersioneRiga),
                Text("@Utente", adeguamento.Utente, 256)
            ],
            cancellationToken);
    }

    public async Task ConfermaAdeguamentoAsync(
        CampionaturaAdeguamentoConfermaModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Campionature_Adeguamenti_Applicazione_Conferma",
            [
                new SqlParameter("@IdAdeguamento", adeguamento.IdAdeguamento),
                RowVersion("@VersioneRiga", adeguamento.VersioneRiga),
                RowVersion("@VersioneRilievo", adeguamento.VersioneRilievo),
                Text("@Utente", adeguamento.Utente, 256)
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

    private static SqlParameter Text(string name, string value) =>
        new(name, SqlDbType.NVarChar, -1) { Value = value.Trim() };

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

    private static SqlParameter Decimal(string name, decimal value) =>
        new(name, SqlDbType.Decimal)
        {
            Precision = 18,
            Scale = 2,
            Value = value
        };

    private static SqlParameter RowVersion(string name, byte[] value) =>
        new(name, SqlDbType.Timestamp, 8) { Value = value };
}

using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class AnagraficheProduttiveRepository : IAnagraficheProduttiveRepository
{
    private readonly DatabaseExecutor _db;

    public AnagraficheProduttiveRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public Task<IReadOnlyList<UnitaMisuraLookupItem>> GetUnitaMisuraAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<UnitaMisuraLookupItem>(
            "dbo.Anagrafiche_UnitaMisura_Lookup",
            [NullableInt("@IdCorrente", idCorrente)],
            cancellationToken);

    public Task<IReadOnlyList<FornitoreAnagraficaLookupItem>> GetFornitoriAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<FornitoreAnagraficaLookupItem>(
            "dbo.Anagrafiche_Fornitori_Lookup",
            [NullableInt("@IdCorrente", idCorrente)],
            cancellationToken);

    public Task<IReadOnlyList<MaterialeListItem>> GetMaterialiAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        string? tipoMateriale = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<MaterialeListItem>(
            "dbo.Anagrafiche_Materiali_Elenco",
            [
                NullableText("@Ricerca", ricerca, 200),
                NullableBit("@SoloAttivi", soloAttivi),
                NullableText("@TipoMateriale", tipoMateriale, 30)
            ],
            cancellationToken);

    public Task<MaterialeDettaglio?> GetMaterialeAsync(int idMateriale, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<MaterialeDettaglio>(
            "dbo.Anagrafiche_Materiali_Dettaglio",
            [new SqlParameter("@IdMateriale", idMateriale)],
            cancellationToken);

    public Task<int> CreaMaterialeAsync(MaterialeCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>(
            "dbo.Anagrafiche_Materiali_Crea",
            ParametriMateriale(modello),
            cancellationToken);

    public Task AggiornaMaterialeAsync(MaterialeUpdateModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync(
            "dbo.Anagrafiche_Materiali_Aggiorna",
            [
                new SqlParameter("@IdMateriale", modello.IdMateriale),
                .. ParametriMateriale(modello),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);

    public Task ImpostaStatoMaterialeAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default) =>
        ImpostaStatoAsync("dbo.Anagrafiche_Materiali_ImpostaStato", "@IdMateriale", modello, cancellationToken);

    public Task EliminaMaterialeAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default) =>
        EliminaAsync("dbo.Anagrafiche_Materiali_Elimina", "@IdMateriale", modello, cancellationToken);

    public Task<IReadOnlyList<LavorazioneListItem>> GetLavorazioniAsync(
        string? ricerca = null,
        bool? soloAttive = null,
        string? internaEsterna = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<LavorazioneListItem>(
            "dbo.Anagrafiche_Lavorazioni_Elenco",
            [
                NullableText("@Ricerca", ricerca, 200),
                NullableBit("@SoloAttive", soloAttive),
                NullableText("@InternaEsterna", internaEsterna, 20)
            ],
            cancellationToken);

    public Task<LavorazioneDettaglio?> GetLavorazioneAsync(int idLavorazione, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<LavorazioneDettaglio>(
            "dbo.Anagrafiche_Lavorazioni_Dettaglio",
            [new SqlParameter("@IdLavorazione", idLavorazione)],
            cancellationToken);

    public Task<int> CreaLavorazioneAsync(LavorazioneCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>(
            "dbo.Anagrafiche_Lavorazioni_Crea",
            ParametriLavorazione(modello),
            cancellationToken);

    public Task AggiornaLavorazioneAsync(LavorazioneUpdateModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync(
            "dbo.Anagrafiche_Lavorazioni_Aggiorna",
            [
                new SqlParameter("@IdLavorazione", modello.IdLavorazione),
                .. ParametriLavorazione(modello),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);

    public Task ImpostaStatoLavorazioneAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default) =>
        ImpostaStatoAsync("dbo.Anagrafiche_Lavorazioni_ImpostaStato", "@IdLavorazione", modello, cancellationToken);

    public Task EliminaLavorazioneAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default) =>
        EliminaAsync("dbo.Anagrafiche_Lavorazioni_Elimina", "@IdLavorazione", modello, cancellationToken);

    private async Task EseguiAsync(string procedura, IEnumerable<SqlParameter> parametri, CancellationToken cancellationToken)
    {
        await _db.ExecuteAsync(procedura, parametri, cancellationToken);
    }

    private Task ImpostaStatoAsync(
        string procedura,
        string parametroId,
        AnagraficaProduttivaStatoModel modello,
        CancellationToken cancellationToken) =>
        EseguiAsync(
            procedura,
            [
                new SqlParameter(parametroId, modello.Id),
                new SqlParameter("@Attivo", SqlDbType.Bit) { Value = modello.Attivo },
                Text("@Utente", modello.Utente, 256),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);

    private Task EliminaAsync(
        string procedura,
        string parametroId,
        AnagraficaProduttivaDeleteModel modello,
        CancellationToken cancellationToken) =>
        EseguiAsync(
            procedura,
            [new SqlParameter(parametroId, modello.Id), RowVersion(modello.VersioneRiga)],
            cancellationToken);

    private static IEnumerable<SqlParameter> ParametriMateriale(MaterialeCreateModel modello) =>
    [
        Text("@CodiceMateriale", modello.CodiceMateriale, 50),
        Text("@Descrizione", modello.Descrizione, 200),
        new SqlParameter("@IdUM", modello.IdUM),
        Text("@TipoMateriale", modello.TipoMateriale, 30),
        Decimal("@CostoUnitario", modello.CostoUnitario, 18, 4),
        new SqlParameter("@GestitoAAcquisto", SqlDbType.Bit) { Value = modello.GestitoAAcquisto },
        NullableInt("@IdFornitorePredefinito", modello.IdFornitorePredefinito),
        NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static IEnumerable<SqlParameter> ParametriLavorazione(LavorazioneCreateModel modello) =>
    [
        Text("@CodiceLavorazione", modello.CodiceLavorazione, 50),
        Text("@Descrizione", modello.Descrizione, 150),
        Text("@InternaEsterna", modello.InternaEsterna, 20),
        Decimal("@CostoOrarioStandard", modello.CostoOrarioStandard, 18, 4),
        Decimal("@TempoSetupMinDefault", modello.TempoSetupMinDefault, 18, 2),
        Decimal("@TempoPezzoMinDefault", modello.TempoPezzoMinDefault, 18, 4),
        new SqlParameter("@AcquistabileEsterna", SqlDbType.Bit) { Value = modello.AcquistabileEsterna },
        NullableInt("@IdFornitorePredefinito", modello.IdFornitorePredefinito),
        NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static SqlParameter Text(string nome, string valore, int dimensione) =>
        new(nome, SqlDbType.NVarChar, dimensione) { Value = valore.Trim() };
    private static SqlParameter NullableText(string nome, string? valore, int dimensione) =>
        new(nome, SqlDbType.NVarChar, dimensione)
        {
            Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim()
        };
    private static SqlParameter NullableInt(string nome, int? valore) =>
        new(nome, SqlDbType.Int) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter NullableBit(string nome, bool? valore) =>
        new(nome, SqlDbType.Bit) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter Decimal(string nome, decimal valore, byte precisione, byte scala) =>
        new(nome, SqlDbType.Decimal) { Precision = precisione, Scale = scala, Value = valore };
    private static SqlParameter RowVersion(byte[] valore) =>
        new("@VersioneRiga", SqlDbType.Timestamp, 8) { Value = valore };
}

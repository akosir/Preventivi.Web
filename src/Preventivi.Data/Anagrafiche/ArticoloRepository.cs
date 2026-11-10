using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class ArticoloRepository : IArticoloRepository
{
    private readonly DatabaseExecutor _db;

    public ArticoloRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public Task<IReadOnlyList<ClienteAnagraficaLookupItem>> GetClientiAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<ClienteAnagraficaLookupItem>(
            "dbo.Anagrafiche_Clienti_Lookup",
            [NullableInt("@IdCorrente", idCorrente)],
            cancellationToken);

    public Task<IReadOnlyList<ArticoloListItem>> GetElencoAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        int? idCliente = null,
        CancellationToken cancellationToken = default) =>
        _db.QueryAsync<ArticoloListItem>(
            "dbo.Anagrafiche_Articoli_Elenco",
            [
                NullableText("@Ricerca", ricerca, 200),
                NullableBit("@SoloAttivi", soloAttivi),
                NullableInt("@IdCliente", idCliente)
            ],
            cancellationToken);

    public Task<ArticoloDettaglio?> GetDettaglioAsync(
        int idArticolo,
        CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<ArticoloDettaglio>(
            "dbo.Anagrafiche_Articoli_Dettaglio",
            [new SqlParameter("@IdArticolo", idArticolo)],
            cancellationToken);

    public Task<int> CreaAsync(
        ArticoloCreateModel modello,
        CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>(
            "dbo.Anagrafiche_Articoli_Crea",
            Parametri(modello),
            cancellationToken);

    public async Task AggiornaAsync(
        ArticoloUpdateModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Anagrafiche_Articoli_Aggiorna",
            [
                new SqlParameter("@IdArticolo", modello.IdArticolo),
                .. Parametri(modello),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task ImpostaStatoAsync(
        AnagraficaProduttivaStatoModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Anagrafiche_Articoli_ImpostaStato",
            [
                new SqlParameter("@IdArticolo", modello.Id),
                new SqlParameter("@Attivo", SqlDbType.Bit) { Value = modello.Attivo },
                Text("@Utente", modello.Utente, 256),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task EliminaAsync(
        AnagraficaProduttivaDeleteModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            "dbo.Anagrafiche_Articoli_Elimina",
            [
                new SqlParameter("@IdArticolo", modello.Id),
                RowVersion(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    private static IEnumerable<SqlParameter> Parametri(ArticoloCreateModel modello) =>
    [
        Text("@CodiceArticolo", modello.CodiceArticolo, 50),
        Text("@Descrizione", modello.Descrizione, 200),
        NullableText("@Versione", modello.Versione, 20),
        NullableInt("@IdCliente", modello.IdCliente),
        NullableText("@NoteTecniche", modello.NoteTecniche, -1),
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

    private static SqlParameter RowVersion(byte[] valore) =>
        new("@VersioneRiga", SqlDbType.Timestamp, 8) { Value = valore };
}

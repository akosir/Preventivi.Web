using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class DistintaBaseRepository : IDistintaBaseRepository
{
    private readonly DatabaseExecutor _db;

    public DistintaBaseRepository(DatabaseExecutor db) => _db = db;

    public Task<IReadOnlyList<DistintaArticoloListItem>> GetArticoliAsync(string? ricerca = null, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaArticoloListItem>("dbo.Anagrafiche_Distinte_Articoli", [NullableText("@Ricerca", ricerca, 200)], cancellationToken);

    public Task<IReadOnlyList<DistintaRevisioneListItem>> GetRevisioniAsync(int idArticolo, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaRevisioneListItem>("dbo.Anagrafiche_Distinte_Revisioni_Elenco", [new SqlParameter("@IdArticolo", idArticolo)], cancellationToken);

    public Task<DistintaRevisioneDettaglio?> GetRevisioneAsync(int idRevisioneDistinta, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<DistintaRevisioneDettaglio>("dbo.Anagrafiche_Distinte_Revisioni_Dettaglio", [new SqlParameter("@IdRevisioneDistinta", idRevisioneDistinta)], cancellationToken);

    public Task<int> CreaBozzaAsync(DistintaRevisioneCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>("dbo.Anagrafiche_Distinte_Revisioni_CreaBozza",
        [
            new SqlParameter("@IdArticolo", modello.IdArticolo),
            NullableText("@Note", modello.Note, 500),
            Text("@Utente", modello.Utente, 256)
        ], cancellationToken);

    public Task PubblicaAsync(DistintaRevisionePubblicaModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Revisioni_Pubblica",
        [
            new SqlParameter("@IdRevisioneDistinta", modello.IdRevisioneDistinta),
            Text("@Motivazione", modello.Motivazione, 500),
            Text("@Utente", modello.Utente, 256),
            RowVersion(modello.VersioneRiga)
        ], cancellationToken);

    public Task CompensaDuplicazioneAsync(int idRevisioneDistinta, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_CompensaDuplicazione",
            [new SqlParameter("@IdRevisioneDistinta", idRevisioneDistinta)], cancellationToken);

    public Task ImportaAsync(DistintaImportazioneRequest richiesta, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Importazioni_Applica",
        [
            new SqlParameter("@IdImportazione", SqlDbType.UniqueIdentifier) { Value = richiesta.IdImportazione },
            new SqlParameter("@IdRevisioneDistinta", richiesta.IdRevisioneDistinta),
            Text("@NomeFile", richiesta.NomeFile, 260),
            new SqlParameter("@ImprontaSha256", SqlDbType.Char, 64) { Value = richiesta.ImprontaSha256 },
            Text("@Utente", richiesta.Utente, 256),
            RowVersion(richiesta.VersioneRiga),
            Structured("@Nodi", "dbo.TVP_DistintaImportazioneNodi", CreaNodi(richiesta.Nodi)),
            Structured("@Materiali", "dbo.TVP_DistintaImportazioneMateriali", CreaMateriali(richiesta.Materiali)),
            Structured("@Lavorazioni", "dbo.TVP_DistintaImportazioneLavorazioni", CreaLavorazioni(richiesta.Lavorazioni))
        ], cancellationToken);

    public Task<IReadOnlyList<TipoNodoDistintaLookupItem>> GetTipiNodoAsync(int? idCorrente = null, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<TipoNodoDistintaLookupItem>("dbo.Anagrafiche_Distinte_TipiNodo_Lookup", [NullableInt("@IdCorrente", idCorrente)], cancellationToken);

    public Task<IReadOnlyList<DistintaNodoItem>> GetNodiAsync(int idRevisioneDistinta, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaNodoItem>("dbo.Anagrafiche_Distinte_Nodi_Elenco", [new SqlParameter("@IdRevisioneDistinta", idRevisioneDistinta)], cancellationToken);

    public Task<DistintaNodoDettaglio?> GetNodoAsync(int idNodoDistinta, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<DistintaNodoDettaglio>("dbo.Anagrafiche_Distinte_Nodi_Dettaglio", [new SqlParameter("@IdNodoDistinta", idNodoDistinta)], cancellationToken);

    public Task<int> CreaNodoAsync(DistintaNodoCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>("dbo.Anagrafiche_Distinte_Nodi_Crea",
            [.. ParametriNodo(modello), Bit("@ConsentiTipoNodoNonAttivo", modello.ConsentiTipoNodoNonAttivo),
             NullableInt("@IdNodoRevisioneOrigine", modello.IdNodoRevisioneOrigine)], cancellationToken);

    public Task AggiornaNodoAsync(DistintaNodoUpdateModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Nodi_Aggiorna", [new SqlParameter("@IdNodoDistinta", modello.IdNodoDistinta), .. ParametriNodo(modello), RowVersion(modello.VersioneRiga)], cancellationToken);

    public Task ImpostaStatoNodoAsync(DistintaNodoStatoModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Nodi_ImpostaStato", [new SqlParameter("@IdNodoDistinta", modello.IdNodoDistinta), Bit("@Attivo", modello.Attivo), Text("@Utente", modello.Utente, 256), RowVersion(modello.VersioneRiga)], cancellationToken);

    public Task EliminaNodoAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default) =>
        EliminaAsync("dbo.Anagrafiche_Distinte_Nodi_Elimina", "@IdNodoDistinta", modello, cancellationToken);

    public Task<IReadOnlyList<DistintaMaterialeLookupItem>> GetMaterialiLookupAsync(int? idCorrente = null, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaMaterialeLookupItem>("dbo.Anagrafiche_Distinte_Materiali_Lookup", [NullableInt("@IdCorrente", idCorrente)], cancellationToken);

    public Task<IReadOnlyList<DistintaMaterialeDettaglio>> GetMaterialiAsync(int idNodoDistinta, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaMaterialeDettaglio>("dbo.Anagrafiche_Distinte_Materiali_Elenco", [new SqlParameter("@IdNodoDistinta", idNodoDistinta)], cancellationToken);

    public Task<DistintaMaterialeDettaglio?> GetMaterialeAsync(int idDistintaMateriale, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<DistintaMaterialeDettaglio>("dbo.Anagrafiche_Distinte_Materiali_Dettaglio", [new SqlParameter("@IdDistintaMateriale", idDistintaMateriale)], cancellationToken);

    public Task<int> CreaMaterialeAsync(DistintaMaterialeCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>("dbo.Anagrafiche_Distinte_Materiali_Crea", [.. ParametriMateriale(modello), Bit("@ConsentiAnagraficaNonAttiva", modello.ConsentiAnagraficaNonAttiva)], cancellationToken);

    public Task AggiornaMaterialeAsync(DistintaMaterialeUpdateModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Materiali_Aggiorna", [new SqlParameter("@IdDistintaMateriale", modello.IdDistintaMateriale), .. ParametriMateriale(modello), RowVersion(modello.VersioneRiga)], cancellationToken);

    public Task EliminaMaterialeAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default) =>
        EliminaAsync("dbo.Anagrafiche_Distinte_Materiali_Elimina", "@IdDistintaMateriale", modello, cancellationToken);

    public Task<IReadOnlyList<DistintaLavorazioneLookupItem>> GetLavorazioniLookupAsync(int? idCorrente = null, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaLavorazioneLookupItem>("dbo.Anagrafiche_Distinte_Lavorazioni_Lookup", [NullableInt("@IdCorrente", idCorrente)], cancellationToken);

    public Task<IReadOnlyList<DistintaLavorazioneDettaglio>> GetLavorazioniAsync(int idNodoDistinta, CancellationToken cancellationToken = default) =>
        _db.QueryAsync<DistintaLavorazioneDettaglio>("dbo.Anagrafiche_Distinte_Lavorazioni_Elenco", [new SqlParameter("@IdNodoDistinta", idNodoDistinta)], cancellationToken);

    public Task<DistintaLavorazioneDettaglio?> GetLavorazioneAsync(int idDistintaLavorazione, CancellationToken cancellationToken = default) =>
        _db.QuerySingleAsync<DistintaLavorazioneDettaglio>("dbo.Anagrafiche_Distinte_Lavorazioni_Dettaglio", [new SqlParameter("@IdDistintaLavorazione", idDistintaLavorazione)], cancellationToken);

    public Task<int> CreaLavorazioneAsync(DistintaLavorazioneCreateModel modello, CancellationToken cancellationToken = default) =>
        _db.ExecuteScalarAsync<int>("dbo.Anagrafiche_Distinte_Lavorazioni_Crea",
            [.. ParametriLavorazione(modello),
             Bit("@ConsentiAnagraficaNonAttiva", modello.ConsentiAnagraficaNonAttiva),
             NullableInt("@IdModelloCiclo", modello.IdModelloCiclo)], cancellationToken);

    public Task AggiornaLavorazioneAsync(DistintaLavorazioneUpdateModel modello, CancellationToken cancellationToken = default) =>
        EseguiAsync("dbo.Anagrafiche_Distinte_Lavorazioni_Aggiorna", [new SqlParameter("@IdDistintaLavorazione", modello.IdDistintaLavorazione), .. ParametriLavorazione(modello), RowVersion(modello.VersioneRiga)], cancellationToken);

    public Task EliminaLavorazioneAsync(DistintaElementoDeleteModel modello, CancellationToken cancellationToken = default) =>
        EliminaAsync("dbo.Anagrafiche_Distinte_Lavorazioni_Elimina", "@IdDistintaLavorazione", modello, cancellationToken);

    private async Task EseguiAsync(string procedura, IEnumerable<SqlParameter> parametri, CancellationToken cancellationToken) =>
        await _db.ExecuteAsync(procedura, parametri, cancellationToken);

    private Task EliminaAsync(string procedura, string parametroId, DistintaElementoDeleteModel modello, CancellationToken cancellationToken) =>
        EseguiAsync(procedura, [new SqlParameter(parametroId, modello.Id), RowVersion(modello.VersioneRiga)], cancellationToken);

    private static IEnumerable<SqlParameter> ParametriNodo(DistintaNodoCreateModel modello) =>
    [
        new SqlParameter("@IdArticolo", modello.IdArticolo), new SqlParameter("@IdRevisioneDistinta", modello.IdRevisioneDistinta),
        NullableInt("@IdNodoPadre", modello.IdNodoPadre),
        new SqlParameter("@IdTipoNodo", modello.IdTipoNodo), NullableText("@CodiceNodo", modello.CodiceNodo, 50),
        Text("@DescrizioneNodo", modello.DescrizioneNodo, 200), Decimal("@QuantitaBase", modello.QuantitaBase, 18, 4),
        new SqlParameter("@OrdineVisualizzazione", modello.OrdineVisualizzazione), NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static IEnumerable<SqlParameter> ParametriMateriale(DistintaMaterialeCreateModel modello) =>
    [
        new SqlParameter("@IdNodoDistinta", modello.IdNodoDistinta), new SqlParameter("@IdMateriale", modello.IdMateriale),
        Decimal("@Quantita", modello.Quantita, 18, 4), Decimal("@CoeffScartoPerc", modello.CoeffScartoPerc, 9, 2),
        Decimal("@CostoUnitario", modello.CostoUnitario, 18, 4), NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static IEnumerable<SqlParameter> ParametriLavorazione(DistintaLavorazioneCreateModel modello) =>
    [
        new SqlParameter("@IdNodoDistinta", modello.IdNodoDistinta), new SqlParameter("@IdLavorazione", modello.IdLavorazione),
        new SqlParameter("@Sequenza", modello.Sequenza), Decimal("@TempoSetupMin", modello.TempoSetupMin, 18, 2),
        Decimal("@TempoPezzoMin", modello.TempoPezzoMin, 18, 4), Decimal("@CostoOrario", modello.CostoOrario, 18, 4),
        Decimal("@CostoFisso", modello.CostoFisso, 18, 4), NullableText("@Note", modello.Note, 500),
        Text("@Utente", modello.Utente, 256)
    ];

    private static SqlParameter Text(string nome, string valore, int dimensione) => new(nome, SqlDbType.NVarChar, dimensione) { Value = valore.Trim() };
    private static SqlParameter NullableText(string nome, string? valore, int dimensione) => new(nome, SqlDbType.NVarChar, dimensione) { Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim() };
    private static SqlParameter NullableInt(string nome, int? valore) => new(nome, SqlDbType.Int) { Value = (object?)valore ?? DBNull.Value };
    private static SqlParameter Decimal(string nome, decimal valore, byte precisione, byte scala) => new(nome, SqlDbType.Decimal) { Precision = precisione, Scale = scala, Value = valore };
    private static SqlParameter Bit(string nome, bool valore) => new(nome, SqlDbType.Bit) { Value = valore };
    private static SqlParameter RowVersion(byte[] valore) => new("@VersioneRiga", SqlDbType.Timestamp, 8) { Value = valore };

    private static SqlParameter Structured(string nome, string tipo, DataTable valore) =>
        new(nome, SqlDbType.Structured) { TypeName = tipo, Value = valore };

    private static DataTable CreaNodi(IReadOnlyList<DistintaImportazioneNodo> righe)
    {
        var table = new DataTable();
        table.Columns.Add("RigaExcel", typeof(int));
        table.Columns.Add("ChiaveNodo", typeof(string));
        table.Columns.Add("ChiavePadre", typeof(string));
        table.Columns.Add("TipoNodo", typeof(string));
        table.Columns.Add("CodiceNodo", typeof(string));
        table.Columns.Add("DescrizioneNodo", typeof(string));
        table.Columns.Add("QuantitaBase", typeof(decimal));
        table.Columns.Add("OrdineVisualizzazione", typeof(int));
        table.Columns.Add("Attivo", typeof(bool));
        table.Columns.Add("Note", typeof(string));
        foreach (var riga in righe)
        {
            table.Rows.Add(riga.RigaExcel, riga.ChiaveNodo, Db(riga.ChiavePadre), riga.TipoNodo,
                Db(riga.CodiceNodo), riga.DescrizioneNodo, riga.QuantitaBase,
                riga.OrdineVisualizzazione, riga.Attivo, Db(riga.Note));
        }
        return table;
    }

    private static DataTable CreaMateriali(IReadOnlyList<DistintaImportazioneMateriale> righe)
    {
        var table = new DataTable();
        table.Columns.Add("RigaExcel", typeof(int));
        table.Columns.Add("ChiaveNodo", typeof(string));
        table.Columns.Add("CodiceMateriale", typeof(string));
        table.Columns.Add("Quantita", typeof(decimal));
        table.Columns.Add("CoeffScartoPerc", typeof(decimal));
        table.Columns.Add("CostoUnitario", typeof(decimal));
        table.Columns.Add("Note", typeof(string));
        foreach (var riga in righe)
        {
            table.Rows.Add(riga.RigaExcel, riga.ChiaveNodo, riga.CodiceMateriale,
                riga.Quantita, riga.CoeffScartoPerc, riga.CostoUnitario, Db(riga.Note));
        }
        return table;
    }

    private static DataTable CreaLavorazioni(IReadOnlyList<DistintaImportazioneLavorazione> righe)
    {
        var table = new DataTable();
        table.Columns.Add("RigaExcel", typeof(int));
        table.Columns.Add("ChiaveNodo", typeof(string));
        table.Columns.Add("CodiceLavorazione", typeof(string));
        table.Columns.Add("Sequenza", typeof(int));
        table.Columns.Add("TempoSetupMin", typeof(decimal));
        table.Columns.Add("TempoPezzoMin", typeof(decimal));
        table.Columns.Add("CostoOrario", typeof(decimal));
        table.Columns.Add("CostoFisso", typeof(decimal));
        table.Columns.Add("Note", typeof(string));
        foreach (var riga in righe)
        {
            table.Rows.Add(riga.RigaExcel, riga.ChiaveNodo, riga.CodiceLavorazione,
                riga.Sequenza, riga.TempoSetupMin, riga.TempoPezzoMin,
                riga.CostoOrario, riga.CostoFisso, Db(riga.Note));
        }
        return table;
    }

    private static object Db(string? valore) =>
        string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim();
}

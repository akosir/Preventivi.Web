using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class AnagraficheBaseRepository : IAnagraficheBaseRepository
{
    private readonly DatabaseExecutor _db;

    public AnagraficheBaseRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<AnagraficaBaseListItem>> GetElencoAsync(
        TipoAnagraficaBase tipo,
        string? ricerca = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<AnagraficaBaseListItem>(
            Procedura(tipo, "Elenco"),
            [
                TestoNullable("@Ricerca", ricerca, 100),
                new SqlParameter("@SoloAttivi", System.Data.SqlDbType.Bit)
                {
                    Value = (object?)soloAttivi ?? DBNull.Value
                }
            ],
            cancellationToken);
    }

    public async Task<AnagraficaBaseDettaglio?> GetDettaglioAsync(
        TipoAnagraficaBase tipo,
        int id,
        CancellationToken cancellationToken = default)
    {
        return await _db.QuerySingleAsync<AnagraficaBaseDettaglio>(
            Procedura(tipo, "Dettaglio"),
            [new SqlParameter(ParametroId(tipo), id)],
            cancellationToken);
    }

    public async Task<int> CreaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseCreateModel modello,
        CancellationToken cancellationToken = default)
    {
        return await _db.ExecuteScalarAsync<int>(
            Procedura(tipo, "Crea"),
            ParametriDati(tipo, modello.Codice, modello.Descrizione, modello.Utente),
            cancellationToken);
    }

    public async Task AggiornaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseUpdateModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            Procedura(tipo, "Aggiorna"),
            [
                new SqlParameter(ParametroId(tipo), modello.Id),
                .. ParametriDati(tipo, modello.Codice, modello.Descrizione, modello.Utente),
                Versione(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task ImpostaStatoAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseStatoModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            Procedura(tipo, "ImpostaStato"),
            [
                new SqlParameter(ParametroId(tipo), modello.Id),
                new SqlParameter("@Attivo", modello.Attivo),
                Testo("@Utente", modello.Utente, 256),
                Versione(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    public async Task EliminaAsync(
        TipoAnagraficaBase tipo,
        AnagraficaBaseDeleteModel modello,
        CancellationToken cancellationToken = default)
    {
        await _db.ExecuteAsync(
            Procedura(tipo, "Elimina"),
            [
                new SqlParameter(ParametroId(tipo), modello.Id),
                Versione(modello.VersioneRiga)
            ],
            cancellationToken);
    }

    private static IEnumerable<SqlParameter> ParametriDati(
        TipoAnagraficaBase tipo,
        string? codice,
        string descrizione,
        string utente)
    {
        if (tipo == TipoAnagraficaBase.UnitaMisura)
        {
            yield return Testo("@CodiceUM", codice ?? string.Empty, 10);
        }

        yield return Testo("@Descrizione", descrizione, tipo == TipoAnagraficaBase.UnitaMisura ? 50 : 100);
        yield return Testo("@Utente", utente, 256);
    }

    private static string Procedura(TipoAnagraficaBase tipo, string azione) =>
        $"dbo.{(tipo == TipoAnagraficaBase.UnitaMisura ? "UnitaMisura" : "TipiNodoDistinta")}_{azione}";

    private static string ParametroId(TipoAnagraficaBase tipo) =>
        tipo == TipoAnagraficaBase.UnitaMisura ? "@IdUM" : "@IdTipoNodo";

    private static SqlParameter Testo(string nome, string valore, int dimensione) =>
        new(nome, System.Data.SqlDbType.NVarChar, dimensione) { Value = valore.Trim() };

    private static SqlParameter TestoNullable(string nome, string? valore, int dimensione) =>
        new(nome, System.Data.SqlDbType.NVarChar, dimensione)
        {
            Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim()
        };

    private static SqlParameter Versione(byte[] valore) =>
        new("@VersioneRiga", System.Data.SqlDbType.Timestamp, 8) { Value = valore };
}

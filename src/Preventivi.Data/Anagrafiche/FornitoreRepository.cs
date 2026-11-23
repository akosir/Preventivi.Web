using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class FornitoreRepository(DatabaseExecutor db) : IFornitoreRepository
{
    public Task<IReadOnlyList<FornitoreDettaglio>> GetElencoAsync(string? ricerca = null,
        bool? soloAttivi = null, CancellationToken cancellationToken = default) =>
        db.QueryAsync<FornitoreDettaglio>("dbo.Anagrafiche_Fornitori_Elenco",
            [Testo("@Ricerca", ricerca, 200),
             new SqlParameter("@SoloAttivi", SqlDbType.Bit) { Value = (object?)soloAttivi ?? DBNull.Value }],
            cancellationToken);

    public Task<FornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default) =>
        db.QuerySingleAsync<FornitoreDettaglio>("dbo.Anagrafiche_Fornitori_Dettaglio",
            [new SqlParameter("@IdFornitore", id)], cancellationToken);

    public Task<IReadOnlyList<FornitoreDipendenza>> GetDipendenzeAsync(int id, CancellationToken cancellationToken = default) =>
        db.QueryAsync<FornitoreDipendenza>("dbo.Anagrafiche_Fornitori_Dipendenze",
            [new SqlParameter("@IdFornitore", id)], cancellationToken);

    public Task<int> CreaAsync(FornitoreCreateModel modello, CancellationToken cancellationToken = default) =>
        db.ExecuteScalarAsync<int>("dbo.Anagrafiche_Fornitori_Crea", Parametri(modello), cancellationToken);

    public async Task AggiornaAsync(FornitoreUpdateModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_Fornitori_Aggiorna",
            [new SqlParameter("@IdFornitore", modello.IdFornitore), .. Parametri(modello), Versione(modello.VersioneRiga)],
            cancellationToken);

    public async Task ImpostaStatoAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_Fornitori_ImpostaStato",
            [new SqlParameter("@IdFornitore", modello.Id), new SqlParameter("@Attivo", modello.Attivo),
             Testo("@Utente", modello.Utente, 256), Versione(modello.VersioneRiga)], cancellationToken);

    public async Task EliminaAsync(int id, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default) =>
        await db.ExecuteAsync("dbo.Anagrafiche_Fornitori_Elimina",
            [new SqlParameter("@IdFornitore", id), Versione(versioneRiga), Testo("@Utente", utente, 256)],
            cancellationToken);

    private static IEnumerable<SqlParameter> Parametri(FornitoreCreateModel modello) =>
    [
        Testo("@CodiceFornitore", modello.CodiceFornitore, 30),
        Testo("@RagioneSociale", modello.RagioneSociale, 150),
        Testo("@PartitaIVA", modello.PartitaIVA, 20),
        Testo("@CodiceFiscale", modello.CodiceFiscale, 20),
        Testo("@Indirizzo", modello.Indirizzo, 150),
        Testo("@CAP", modello.CAP, 10),
        Testo("@Citta", modello.Citta, 100),
        Testo("@Provincia", modello.Provincia, 10),
        Testo("@Telefono", modello.Telefono, 50),
        Testo("@Email", modello.Email, 150),
        Testo("@Referente", modello.Referente, 100),
        Testo("@Utente", modello.Utente, 256)
    ];

    private static SqlParameter Testo(string nome, string? valore, int dimensione) =>
        new(nome, SqlDbType.NVarChar, dimensione)
        {
            Value = string.IsNullOrWhiteSpace(valore) ? DBNull.Value : valore.Trim()
        };

    private static SqlParameter Versione(byte[] valore) =>
        new("@VersioneRiga", SqlDbType.Timestamp, 8) { Value = valore };
}

using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Anagrafiche;

public sealed class ArticoliImportazioneRepository(DatabaseExecutor database) : IArticoliImportazioneRepository
{
    public Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(
        IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default) =>
        LeggiErroriAsync(righe, cancellationToken);

    private async Task<IReadOnlyList<ArticoliImportazioneErrore>> LeggiErroriAsync(
        IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken)
    {
        var errori = await database.QueryAsync<ErroreSql>(
            "dbo.Anagrafiche_Articoli_Importazione_Valida", [Json(righe)], cancellationToken);
        return errori.Select(x => new ArticoliImportazioneErrore("Articoli", x.RigaExcel, x.Campo, x.Messaggio)).ToArray();
    }

    public async Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default) =>
        await database.ExecuteScalarAsync<int>("dbo.Anagrafiche_Articoli_Importazione_Applica",
        [
            new SqlParameter("@IdImportazione", SqlDbType.UniqueIdentifier) { Value = richiesta.IdImportazione },
            new SqlParameter("@NomeFile", SqlDbType.NVarChar, 260) { Value = richiesta.NomeFile },
            new SqlParameter("@ImprontaSha256", SqlDbType.Char, 64) { Value = richiesta.ImprontaSha256 },
            new SqlParameter("@Utente", SqlDbType.NVarChar, 256) { Value = richiesta.Utente },
            Json(richiesta.Righe)
        ], cancellationToken);

    private static SqlParameter Json(IReadOnlyList<ArticoloImportazioneRiga> righe) =>
        new("@Righe", SqlDbType.NVarChar, -1) { Value = JsonSerializer.Serialize(righe) };

    public sealed class ErroreSql
    {
        public int RigaExcel { get; set; }
        public string Campo { get; set; } = string.Empty;
        public string Messaggio { get; set; } = string.Empty;
    }
}

using System.Data;
using System.Text.Json;
using Microsoft.Data.SqlClient;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Data.Comune;

namespace Preventivi.Data.OrdiniFornitori;

public sealed class GenerazioneOrdiniFornitoriRepository(DatabaseExecutor db) : IGenerazioneOrdiniFornitoriRepository
{
    public Task<IReadOnlyList<AcquistoPreventivo>> GetAnteprimaAsync(int idPreventivo, int? idRigaPreventivo,
        CancellationToken cancellationToken = default) =>
        db.QueryAsync<AcquistoPreventivo>("dbo.OrdiniFornitori_Generazione_Anteprima",
            [new("@IdPreventivo", SqlDbType.Int) { Value = idPreventivo },
             new("@IdRigaPreventivo", SqlDbType.Int) { Value = (object?)idRigaPreventivo ?? DBNull.Value }], cancellationToken);

    public Task<IReadOnlyList<OrdineFornitoreDettaglio>> ConfermaAsync(int idPreventivo, int? idRigaPreventivo,
        Guid richiesta, DateTime dataOrdine, IReadOnlyList<AcquistoSelezionato> selezione, string utente,
        CancellationToken cancellationToken = default) =>
        db.QueryAsync<OrdineFornitoreDettaglio>("dbo.OrdiniFornitori_Generazione_Conferma",
            [new("@IdPreventivo", SqlDbType.Int) { Value = idPreventivo },
             new("@IdRigaPreventivo", SqlDbType.Int) { Value = (object?)idRigaPreventivo ?? DBNull.Value },
             new("@Richiesta", SqlDbType.UniqueIdentifier) { Value = richiesta },
             new("@DataOrdine", SqlDbType.Date) { Value = dataOrdine.Date },
             new("@Selezione", SqlDbType.NVarChar, -1) { Value = JsonSerializer.Serialize(selezione) },
             new("@Utente", SqlDbType.NVarChar, 256) { Value = utente }], cancellationToken);
}

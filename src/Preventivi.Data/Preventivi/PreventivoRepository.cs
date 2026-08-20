using Preventivi.Core.Preventivi;
using Preventivi.Data.Comune;
using Microsoft.Data.SqlClient;

namespace Preventivi.Data.Preventivi;

public sealed class PreventivoRepository : IPreventivoRepository
{
    private readonly DatabaseExecutor _db;

    public PreventivoRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<PreventivoListItem>> GetElencoAsync(
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<PreventivoListItem>(
            "dbo.Preventivi_Elenco",
            cancellationToken: cancellationToken);
    }

    public async Task<PreventivoDettaglio?> GetDettaglioAsync(
    int idPreventivo,
    CancellationToken cancellationToken = default)
    {
        var parameters = new[]
        {
        new SqlParameter("@IdPreventivo", idPreventivo)
    };

        return await _db.QuerySingleAsync<PreventivoDettaglio>(
            "dbo.Preventivi_Dettaglio",
            parameters,
            cancellationToken);
    }
}
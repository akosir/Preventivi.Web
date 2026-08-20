using Preventivi.Core.Preventivi;
using Preventivi.Data.Comune;

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
}
using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Preventivi.Eliminazione;
using Preventivi.Data.Comune;

namespace Preventivi.Data.Preventivi;

public sealed class PreventivoEliminazioneRepository
    : IPreventivoEliminazioneRepository
{
    private readonly DatabaseExecutor _db;

    public PreventivoEliminazioneRepository(DatabaseExecutor db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<AllegatoEliminazionePreventivo>> PreparaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        CancellationToken cancellationToken = default)
    {
        return await _db.QueryAsync<AllegatoEliminazionePreventivo>(
            "dbo.Preventivi_Eliminazione_Prepara",
            [
                new SqlParameter("@TipoEliminazione", SqlDbType.TinyInt)
                {
                    Value = (byte)tipo
                },
                new SqlParameter("@IdEntita", SqlDbType.Int)
                {
                    Value = idEntita
                }
            ],
            cancellationToken);
    }

    public async Task EliminaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        IReadOnlyCollection<int> idAllegatiAttesi,
        CancellationToken cancellationToken = default)
    {
        var tabellaId = new DataTable();
        tabellaId.Columns.Add("IdAllegato", typeof(int));

        foreach (var idAllegato in idAllegatiAttesi.Order())
        {
            tabellaId.Rows.Add(idAllegato);
        }

        var parametroAllegati = new SqlParameter(
            "@IdAllegatiAttesi",
            SqlDbType.Structured)
        {
            TypeName = "dbo.IdAllegatoElenco",
            Value = tabellaId
        };

        await _db.ExecuteAsync(
            "dbo.Preventivi_Eliminazione_Conferma",
            [
                new SqlParameter("@TipoEliminazione", SqlDbType.TinyInt)
                {
                    Value = (byte)tipo
                },
                new SqlParameter("@IdEntita", SqlDbType.Int)
                {
                    Value = idEntita
                },
                parametroAllegati
            ],
            cancellationToken);
    }
}

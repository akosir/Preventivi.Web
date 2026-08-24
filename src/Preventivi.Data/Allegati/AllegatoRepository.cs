using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.Allegati;

public sealed class AllegatoRepository : IAllegatoRepository
{
    private readonly SqlConnectionFactory _connectionFactory;

    public AllegatoRepository(
        SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<AllegatoListItem>> GetElencoAsync(
    string entita,
    int idEntita,
    CancellationToken cancellationToken = default)
    {
        var risultati = new List<AllegatoListItem>();

        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Allegati_Elenco",
                connection);

        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@Entita", SqlDbType.NVarChar, 50)
            {
                Value = entita
            });

        command.Parameters.Add(
            new SqlParameter("@IdEntita", SqlDbType.Int)
            {
                Value = idEntita
            });

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            risultati.Add(
                AllegatoMapper.ToListItem(reader));
        }

        return risultati;
    }

    public async Task<AllegatoDettaglio?> GetByIdAsync(
    int idAllegato,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Allegati_Dettaglio",
                connection);

        command.CommandType = CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@IdAllegato", SqlDbType.Int)
            {
                Value = idAllegato
            });

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return AllegatoMapper.ToDettaglio(reader);
    }

    public async Task<int> CreaAsync(
    AllegatoCreateModel allegato,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Allegati_Crea",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.AddWithValue("@Entita", allegato.Entita);
        command.Parameters.AddWithValue("@IdEntita", allegato.IdEntita);
        command.Parameters.AddWithValue("@TipoAllegato",
            (object?)allegato.TipoAllegato ?? DBNull.Value);
        command.Parameters.AddWithValue("@Descrizione",
            (object?)allegato.Descrizione ?? DBNull.Value);
        command.Parameters.AddWithValue("@NomeFileOriginale",
            allegato.NomeFileOriginale);
        command.Parameters.AddWithValue("@NomeFileArchiviato",
            allegato.NomeFileArchiviato);
        command.Parameters.AddWithValue("@PercorsoFile",
            allegato.PercorsoFile);
        command.Parameters.AddWithValue("@Estensione",
            (object?)allegato.Estensione ?? DBNull.Value);
        command.Parameters.AddWithValue("@DataAllegato",
            allegato.DataAllegato.ToDateTime(TimeOnly.MinValue));
        command.Parameters.AddWithValue("@UtenteInserimento",
            (object?)allegato.UtenteInserimento ?? DBNull.Value);
        command.Parameters.AddWithValue("@Note",
            (object?)allegato.Note ?? DBNull.Value);
        command.Parameters.Add(
    new SqlParameter("@DimensioneFile", SqlDbType.BigInt)
    {
        Value = allegato.DimensioneFile.HasValue
            ? allegato.DimensioneFile.Value
            : DBNull.Value
    });
        var risultato =
            await command.ExecuteScalarAsync(cancellationToken);

        return Convert.ToInt32(risultato);
    }

    public async Task EliminaAsync(
    int idAllegato,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Allegati_Elimina",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@IdAllegato", SqlDbType.Int)
            {
                Value = idAllegato
            });

        await command.ExecuteNonQueryAsync(
            cancellationToken);
    }

    public async Task<IReadOnlyList<TipoAllegatoItem>> GetTipiAsync(
        CancellationToken cancellationToken = default)
    {
        var risultati = new List<TipoAllegatoItem>();

        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.TipiAllegato_Elenco",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            risultati.Add(
                AllegatoMapper.ToTipoAllegato(reader));
        }

        return risultati;
    }
}
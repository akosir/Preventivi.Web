using Microsoft.Data.SqlClient;
using System.Data;

namespace Preventivi.Data.Comune;

public sealed class DatabaseExecutor
{
    private readonly SqlConnectionFactory _connectionFactory;

    public DatabaseExecutor(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<T>> QueryAsync<T>(
        string storedProcedure,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
        where T : new()
    {
        var results = new List<T>();

        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(storedProcedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

        if (parameters is not null)
        {
            command.Parameters.AddRange(parameters.ToArray());
        }

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            results.Add(DbMapper.Map<T>(reader));
        }

        return results;
    }

    public async Task<T?> QuerySingleAsync<T>(
        string storedProcedure,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
        where T : new()
    {
        var results = await QueryAsync<T>(
            storedProcedure,
            parameters,
            cancellationToken);

        return results.FirstOrDefault();
    }

    public async Task<int> ExecuteAsync(
        string storedProcedure,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(storedProcedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

        if (parameters is not null)
        {
            command.Parameters.AddRange(parameters.ToArray());
        }

        return await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<T?> ExecuteScalarAsync<T>(
        string storedProcedure,
        IEnumerable<SqlParameter>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(storedProcedure, connection)
            {
                CommandType = CommandType.StoredProcedure
            };

        if (parameters is not null)
        {
            command.Parameters.AddRange(parameters.ToArray());
        }

        var result =
            await command.ExecuteScalarAsync(cancellationToken);

        if (result is null || result == DBNull.Value)
            return default;

        return (T)Convert.ChangeType(
            result,
            Nullable.GetUnderlyingType(typeof(T)) ?? typeof(T));
    }
}
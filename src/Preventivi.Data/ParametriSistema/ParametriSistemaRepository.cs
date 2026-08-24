using Microsoft.Data.SqlClient;
using Preventivi.Core.ParametriSistema;
using Preventivi.Data.Comune;

namespace Preventivi.Data.ParametriSistema;

public sealed class ParametriSistemaRepository
    : IParametriSistemaRepository
{
    private readonly SqlConnectionFactory _connectionFactory;

    public ParametriSistemaRepository(
        SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<string?> GetValoreAsync(
    string chiave,
    CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(chiave))
        {
            throw new ArgumentException(
                "La chiave del parametro non può essere vuota.",
                nameof(chiave));
        }

        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.ParametriSistema_GetValore",
                connection);

        command.CommandType =
            System.Data.CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter(
                "@Chiave",
                System.Data.SqlDbType.NVarChar,
                100)
            {
                Value = chiave
            });

        var risultato =
            await command.ExecuteScalarAsync(
                cancellationToken);

        if (risultato is null ||
            risultato == DBNull.Value)
        {
            return null;
        }

        return Convert.ToString(risultato);
    }
}
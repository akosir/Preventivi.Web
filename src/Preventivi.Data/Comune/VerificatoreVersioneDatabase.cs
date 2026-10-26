using System.Data;
using Microsoft.Data.SqlClient;
using Preventivi.Core.Database;

namespace Preventivi.Data.Comune;

public sealed class VerificatoreVersioneDatabase : IVerificatoreVersioneDatabase
{
    private const int OggettoNonValido = 208;
    private const int ProceduraNonTrovata = 2812;

    private readonly SqlConnectionFactory _connectionFactory;

    public VerificatoreVersioneDatabase(
        SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<StatoSchemaDatabase> VerificaAsync(
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = _connectionFactory.CreateConnection();
            await connection.OpenAsync(cancellationToken);

            await using var command = new SqlCommand(
                "dbo.Sistema_VersioneSchema_Corrente",
                connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await using var reader =
                await command.ExecuteReaderAsync(cancellationToken);

            if (!await reader.ReadAsync(cancellationToken))
            {
                return StatoSchemaDatabase.Valuta(null, null);
            }

            var versione = reader.GetInt32(reader.GetOrdinal("Versione"));
            var codiceOrdinal = reader.GetOrdinal("CodiceIntervento");
            var codice = reader.IsDBNull(codiceOrdinal)
                ? null
                : reader.GetString(codiceOrdinal);

            return StatoSchemaDatabase.Valuta(versione, codice);
        }
        catch (SqlException exception)
            when (exception.Number is OggettoNonValido or ProceduraNonTrovata)
        {
            return StatoSchemaDatabase.Valuta(null, null);
        }
    }
}

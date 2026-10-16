using Microsoft.Data.SqlClient;
using Preventivi.Core.Sicurezza;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.Sicurezza;

public sealed class UtenteAccessoRepository : IUtenteAccessoRepository
{
    private readonly SqlConnectionFactory _connectionFactory;

    public UtenteAccessoRepository(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<UtenteAccesso?> GetByUsernameAsync(
        string username,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            return null;
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            "dbo.Sicurezza_UtenteAccesso_Get",
            connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@Username", SqlDbType.NVarChar, 50)
        {
            Value = username.Trim()
        });

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        var idUtente = reader.GetInt32(reader.GetOrdinal("IdUtente"));
        var usernameNormalizzato = reader.GetString(reader.GetOrdinal("Username"));
        var nomeCompletoOrdinal = reader.GetOrdinal("NomeCompleto");
        var passwordHashOrdinal = reader.GetOrdinal("PasswordHash");
        var nomeCompleto = reader.IsDBNull(nomeCompletoOrdinal)
            ? null
            : reader.GetString(nomeCompletoOrdinal);
        var passwordHash = reader.IsDBNull(passwordHashOrdinal)
            ? null
            : reader.GetString(passwordHashOrdinal);
        var attivo = reader.GetBoolean(reader.GetOrdinal("Attivo"));
        var ruoli = new List<string>();
        var permessi = new List<string>();

        if (await reader.NextResultAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                ruoli.Add(reader.GetString(reader.GetOrdinal("CodiceRuolo")));
            }
        }

        if (await reader.NextResultAsync(cancellationToken))
        {
            while (await reader.ReadAsync(cancellationToken))
            {
                permessi.Add(reader.GetString(reader.GetOrdinal("NomeMaschera")));
            }
        }

        return new UtenteAccesso
        {
            IdUtente = idUtente,
            Username = usernameNormalizzato,
            NomeCompleto = nomeCompleto,
            PasswordHash = passwordHash,
            Attivo = attivo,
            Ruoli = ruoli,
            Permessi = permessi
        };
    }

    public async Task<bool> InizializzaPasswordAdminAsync(
        string username,
        string passwordHash,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await using var command = new SqlCommand(
            "dbo.Sicurezza_AdminPassword_Inizializza",
            connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add(new SqlParameter("@Username", SqlDbType.NVarChar, 50)
        {
            Value = username.Trim()
        });
        command.Parameters.Add(new SqlParameter("@PasswordHash", SqlDbType.NVarChar, 255)
        {
            Value = passwordHash
        });

        var risultato = await command.ExecuteScalarAsync(cancellationToken);
        return Convert.ToInt32(risultato) == 1;
    }
}

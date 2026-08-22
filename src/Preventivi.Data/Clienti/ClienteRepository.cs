using Microsoft.Data.SqlClient;
using Preventivi.Core.Clienti;
using Preventivi.Data.Comune;
using System.Data;

namespace Preventivi.Data.Clienti;

public sealed class ClienteRepository : IClienteRepository
{
    private readonly SqlConnectionFactory _connectionFactory;

    public ClienteRepository(
        SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<ClienteListItem>> GetElencoAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        CancellationToken cancellationToken = default)
    {
        var risultati = new List<ClienteListItem>();

        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Clienti_Elenco",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@Ricerca", SqlDbType.NVarChar, 300)
            {
                Value =
                    string.IsNullOrWhiteSpace(ricerca)
                        ? DBNull.Value
                        : ricerca.Trim()
            });

        command.Parameters.Add(
            new SqlParameter("@SoloAttivi", SqlDbType.Bit)
            {
                Value =
                    soloAttivi.HasValue
                        ? soloAttivi.Value
                        : DBNull.Value
            });

        await using var reader =
            await command.ExecuteReaderAsync(
                cancellationToken);

        while (await reader.ReadAsync(cancellationToken))
        {
            risultati.Add(
                new ClienteListItem
                {
                    IdCliente =
                        reader.GetInt32(
                            reader.GetOrdinal("IdCliente")),

                    CodiceCliente =
                        reader.GetString(
                            reader.GetOrdinal("CodiceCliente")),

                    RagioneSociale =
                        reader.GetString(
                            reader.GetOrdinal("RagioneSociale")),

                    PartitaIVA =
                        reader.IsDBNull(
                            reader.GetOrdinal("PartitaIVA"))
                            ? null
                            : reader.GetString(
                                reader.GetOrdinal("PartitaIVA")),

                    Citta =
                        reader.IsDBNull(
                            reader.GetOrdinal("Citta"))
                            ? null
                            : reader.GetString(
                                reader.GetOrdinal("Citta")),

                    Telefono =
                        reader.IsDBNull(
                            reader.GetOrdinal("Telefono"))
                            ? null
                            : reader.GetString(
                                reader.GetOrdinal("Telefono")),

                    Email =
                        reader.IsDBNull(
                            reader.GetOrdinal("Email"))
                            ? null
                            : reader.GetString(
                                reader.GetOrdinal("Email")),

                    Attivo =
                        reader.GetBoolean(
                            reader.GetOrdinal("Attivo"))
                });
        }

        return risultati;
    }
    public async Task<int> CreaAsync(
    ClienteCreateModel cliente,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Clienti_Crea",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@CodiceCliente", SqlDbType.NVarChar, 50)
            {
                Value = cliente.CodiceCliente
            });

        command.Parameters.Add(
            new SqlParameter("@RagioneSociale", SqlDbType.NVarChar, 200)
            {
                Value = cliente.RagioneSociale
            });

        command.Parameters.Add(
            new SqlParameter("@PartitaIVA", SqlDbType.NVarChar, 30)
            {
                Value = (object?)cliente.PartitaIVA ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@CodiceFiscale", SqlDbType.NVarChar, 30)
            {
                Value = (object?)cliente.CodiceFiscale ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Indirizzo", SqlDbType.NVarChar, 200)
            {
                Value = (object?)cliente.Indirizzo ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@CAP", SqlDbType.NVarChar, 10)
            {
                Value = (object?)cliente.CAP ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Citta", SqlDbType.NVarChar, 100)
            {
                Value = (object?)cliente.Citta ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Provincia", SqlDbType.NVarChar, 10)
            {
                Value = (object?)cliente.Provincia ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Telefono", SqlDbType.NVarChar, 50)
            {
                Value = (object?)cliente.Telefono ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Email", SqlDbType.NVarChar, 200)
            {
                Value = (object?)cliente.Email ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Attivo", SqlDbType.Bit)
            {
                Value = cliente.Attivo
            });

        var risultato =
            await command.ExecuteScalarAsync(cancellationToken);

        return Convert.ToInt32(risultato);
    }

    public async Task<ClienteDettaglio?> GetByIdAsync(
    int idCliente,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Clienti_Dettaglio",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@IdCliente", SqlDbType.Int)
            {
                Value = idCliente
            });

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new ClienteDettaglio
        {
            IdCliente =
                reader.GetInt32(
                    reader.GetOrdinal("IdCliente")),

            CodiceCliente =
                reader.GetString(
                    reader.GetOrdinal("CodiceCliente")),

            RagioneSociale =
                reader.GetString(
                    reader.GetOrdinal("RagioneSociale")),

            PartitaIVA =
                reader.IsDBNull(reader.GetOrdinal("PartitaIVA"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("PartitaIVA")),

            CodiceFiscale =
                reader.IsDBNull(reader.GetOrdinal("CodiceFiscale"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("CodiceFiscale")),

            Indirizzo =
                reader.IsDBNull(reader.GetOrdinal("Indirizzo"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Indirizzo")),

            CAP =
                reader.IsDBNull(reader.GetOrdinal("CAP"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("CAP")),

            Citta =
                reader.IsDBNull(reader.GetOrdinal("Citta"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Citta")),

            Provincia =
                reader.IsDBNull(reader.GetOrdinal("Provincia"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Provincia")),

            Telefono =
                reader.IsDBNull(reader.GetOrdinal("Telefono"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Telefono")),

            Email =
                reader.IsDBNull(reader.GetOrdinal("Email"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("Email")),

            Attivo =
                reader.GetBoolean(
                    reader.GetOrdinal("Attivo"))
        };
    }
    public async Task AggiornaAsync(
    ClienteUpdateModel cliente,
    CancellationToken cancellationToken = default)
    {
        await using var connection =
            _connectionFactory.CreateConnection();

        await connection.OpenAsync(cancellationToken);

        await using var command =
            new SqlCommand(
                "dbo.Clienti_Aggiorna",
                connection);

        command.CommandType =
            CommandType.StoredProcedure;

        command.Parameters.Add(
            new SqlParameter("@IdCliente", SqlDbType.Int)
            {
                Value = cliente.IdCliente
            });

        command.Parameters.Add(
            new SqlParameter("@CodiceCliente", SqlDbType.NVarChar, 50)
            {
                Value = cliente.CodiceCliente
            });

        command.Parameters.Add(
            new SqlParameter("@RagioneSociale", SqlDbType.NVarChar, 200)
            {
                Value = cliente.RagioneSociale
            });

        command.Parameters.Add(
            new SqlParameter("@PartitaIVA", SqlDbType.NVarChar, 30)
            {
                Value = (object?)cliente.PartitaIVA ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@CodiceFiscale", SqlDbType.NVarChar, 30)
            {
                Value = (object?)cliente.CodiceFiscale ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Indirizzo", SqlDbType.NVarChar, 200)
            {
                Value = (object?)cliente.Indirizzo ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@CAP", SqlDbType.NVarChar, 10)
            {
                Value = (object?)cliente.CAP ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Citta", SqlDbType.NVarChar, 100)
            {
                Value = (object?)cliente.Citta ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Provincia", SqlDbType.NVarChar, 10)
            {
                Value = (object?)cliente.Provincia ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Telefono", SqlDbType.NVarChar, 50)
            {
                Value = (object?)cliente.Telefono ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Email", SqlDbType.NVarChar, 200)
            {
                Value = (object?)cliente.Email ?? DBNull.Value
            });

        command.Parameters.Add(
            new SqlParameter("@Attivo", SqlDbType.Bit)
            {
                Value = cliente.Attivo
            });

        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
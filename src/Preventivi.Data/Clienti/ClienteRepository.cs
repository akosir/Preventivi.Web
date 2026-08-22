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
}
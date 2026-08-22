using Preventivi.Core.Clienti;
using Preventivi.Web.UI.Common.DataGrid;

namespace Preventivi.Web.Mappers.Clienti;

public static class ClienteGridMapper
{
    public static DataGridModel ToGrid(
        IReadOnlyList<ClienteListItem> clienti)
    {
        return new DataGridModel
        {
            TitoloVuoto = "Nessun cliente trovato",

            MessaggioVuoto =
                "Non sono presenti clienti che corrispondono ai criteri di ricerca.",

            Colonne =
            [
                new()
                {
                    Chiave = "codice",
                    Titolo = "Codice"
                },

                new()
                {
                    Chiave = "ragioneSociale",
                    Titolo = "Ragione Sociale"
                },

                new()
                {
                    Chiave = "partitaIva",
                    Titolo = "Partita IVA"
                },

                new()
                {
                    Chiave = "citta",
                    Titolo = "Città"
                },

                new()
                {
                    Chiave = "telefono",
                    Titolo = "Telefono"
                },

                new()
                {
                    Chiave = "email",
                    Titolo = "Email"
                },

                new()
                {
                    Chiave = "stato",
                    Titolo = "Stato"
                }
            ],

            Righe = clienti
                .Select(cliente =>
                    new DataGridRowModel
                    {
                        Id = $"cliente-{cliente.IdCliente}",

                        Celle =
                            new Dictionary<string, DataGridCellModel>
                            {
                                ["codice"] = new()
                                {
                                    Testo = cliente.CodiceCliente
                                },

                                ["ragioneSociale"] = new()
                                {
                                    Testo = cliente.RagioneSociale
                                },

                                ["partitaIva"] = new()
                                {
                                    Testo = cliente.PartitaIVA ?? ""
                                },

                                ["citta"] = new()
                                {
                                    Testo = cliente.Citta ?? ""
                                },

                                ["telefono"] = new()
                                {
                                    Testo = cliente.Telefono ?? ""
                                },

                                ["email"] = new()
                                {
                                    Testo = cliente.Email ?? ""
                                },

                                ["stato"] = new()
                                {
                                    Testo =
                                        cliente.Attivo
                                            ? "Attivo"
                                            : "Non attivo",

                                    BadgeVariante =
                                        cliente.Attivo
                                            ? "successo"
                                            : "neutro"
                                }
                            },

                        Azioni =
                        [
                            new()
                            {
                                Testo = "Apri",

                                Url =
                                    $"/Clienti/Dettaglio?id={cliente.IdCliente}",

                                Variante = "secondary"
                            }
                        ]
                    })
                .ToList()
        };
    }
}
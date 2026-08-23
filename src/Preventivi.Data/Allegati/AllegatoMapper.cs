using Microsoft.Data.SqlClient;
using Preventivi.Core.Allegati;

namespace Preventivi.Data.Allegati;

internal static class AllegatoMapper
{
    public static TipoAllegatoItem ToTipoAllegato(
        SqlDataReader reader)
    {
        return new TipoAllegatoItem
        {
            CodiceTipo = reader.GetString(
                reader.GetOrdinal("CodiceTipo")),

            Descrizione = reader.GetString(
                reader.GetOrdinal("Descrizione"))
        };
    }

    public static AllegatoListItem ToListItem(
    SqlDataReader reader)
    {
        return new AllegatoListItem
        {
            IdAllegato = reader.GetInt32(
                reader.GetOrdinal("IdAllegato")),

            TipoAllegato = reader.IsDBNull(
                reader.GetOrdinal("TipoAllegato"))
                    ? ""
                    : reader.GetString(
                        reader.GetOrdinal("TipoAllegato")),

            Descrizione = reader.IsDBNull(
                reader.GetOrdinal("Descrizione"))
                    ? null
                    : reader.GetString(
                        reader.GetOrdinal("Descrizione")),

            NomeFileOriginale = reader.GetString(
                reader.GetOrdinal("NomeFileOriginale")),

            Estensione = reader.IsDBNull(
                reader.GetOrdinal("Estensione"))
                    ? null
                    : reader.GetString(
                        reader.GetOrdinal("Estensione")),

            DataAllegato = DateOnly.FromDateTime(
                reader.GetDateTime(
                    reader.GetOrdinal("DataAllegato"))),

            UtenteInserimento = reader.IsDBNull(
                reader.GetOrdinal("UtenteInserimento"))
                    ? null
                    : reader.GetString(
                        reader.GetOrdinal("UtenteInserimento"))
        };
    }

    public static AllegatoDettaglio ToDettaglio(
    SqlDataReader reader)
    {
        return new AllegatoDettaglio
        {
            IdAllegato = reader.GetInt32(reader.GetOrdinal("IdAllegato")),

            Entita = reader.GetString(reader.GetOrdinal("Entita")),

            IdEntita = reader.GetInt32(reader.GetOrdinal("IdEntita")),

            TipoAllegato = reader.IsDBNull(reader.GetOrdinal("TipoAllegato"))
                ? null
                : reader.GetString(reader.GetOrdinal("TipoAllegato")),

            Descrizione = reader.IsDBNull(reader.GetOrdinal("Descrizione"))
                ? null
                : reader.GetString(reader.GetOrdinal("Descrizione")),

            NomeFileOriginale = reader.GetString(reader.GetOrdinal("NomeFileOriginale")),

            NomeFileArchiviato = reader.GetString(reader.GetOrdinal("NomeFileArchiviato")),

            PercorsoFile = reader.GetString(reader.GetOrdinal("PercorsoFile")),

            Estensione = reader.IsDBNull(reader.GetOrdinal("Estensione"))
                ? null
                : reader.GetString(reader.GetOrdinal("Estensione")),

            DataAllegato = DateOnly.FromDateTime(
                reader.GetDateTime(reader.GetOrdinal("DataAllegato"))),

            UtenteInserimento = reader.IsDBNull(reader.GetOrdinal("UtenteInserimento"))
                ? null
                : reader.GetString(reader.GetOrdinal("UtenteInserimento")),

            Note = reader.IsDBNull(reader.GetOrdinal("Note"))
                ? null
                : reader.GetString(reader.GetOrdinal("Note"))
        };
    }
}
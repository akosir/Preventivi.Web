namespace Preventivi.Core.Database;

public sealed record StatoSchemaDatabase(
    CompatibilitaSchemaDatabase Compatibilita,
    int VersioneSupportata,
    int? VersioneInstallata,
    string? CodiceInterventoInstallato)
{
    public bool Operativo =>
        Compatibilita == CompatibilitaSchemaDatabase.Compatibile;

    public string MessaggioUtente => Compatibilita switch
    {
        CompatibilitaSchemaDatabase.Compatibile =>
            "Il database e compatibile con questa versione dell'applicazione.",
        CompatibilitaSchemaDatabase.NonInizializzato =>
            "Il registro della versione database non e ancora inizializzato.",
        CompatibilitaSchemaDatabase.Obsoleto =>
            "Il database deve essere aggiornato prima di utilizzare l'applicazione.",
        CompatibilitaSchemaDatabase.Futuro =>
            "L'applicazione deve essere aggiornata per utilizzare questo database.",
        _ =>
            "Il database non e attualmente disponibile."
    };

    public static StatoSchemaDatabase Valuta(
        int? versioneInstallata,
        string? codiceInterventoInstallato)
    {
        var compatibilita = versioneInstallata switch
        {
            null => CompatibilitaSchemaDatabase.NonInizializzato,
            < SchemaDatabaseSupportato.Versione =>
                CompatibilitaSchemaDatabase.Obsoleto,
            > SchemaDatabaseSupportato.Versione =>
                CompatibilitaSchemaDatabase.Futuro,
            _ => CompatibilitaSchemaDatabase.Compatibile
        };

        return new StatoSchemaDatabase(
            compatibilita,
            SchemaDatabaseSupportato.Versione,
            versioneInstallata,
            codiceInterventoInstallato);
    }

    public static StatoSchemaDatabase NonDisponibile()
    {
        return new StatoSchemaDatabase(
            CompatibilitaSchemaDatabase.NonDisponibile,
            SchemaDatabaseSupportato.Versione,
            null,
            null);
    }
}

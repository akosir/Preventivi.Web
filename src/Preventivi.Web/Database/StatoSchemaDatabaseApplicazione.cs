using Preventivi.Core.Database;

namespace Preventivi.Web.Database;

public sealed class StatoSchemaDatabaseApplicazione
{
    private StatoSchemaDatabase _stato =
        StatoSchemaDatabase.NonDisponibile();

    public StatoSchemaDatabase Stato => Volatile.Read(ref _stato);

    public void Aggiorna(StatoSchemaDatabase stato)
    {
        ArgumentNullException.ThrowIfNull(stato);
        Interlocked.Exchange(ref _stato, stato);
    }
}

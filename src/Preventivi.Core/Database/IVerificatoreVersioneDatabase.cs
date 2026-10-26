namespace Preventivi.Core.Database;

public interface IVerificatoreVersioneDatabase
{
    Task<StatoSchemaDatabase> VerificaAsync(
        CancellationToken cancellationToken = default);
}

namespace Preventivi.Core.Sicurezza;

public interface IUtenteAccessoRepository
{
    Task<UtenteAccesso?> GetByUsernameAsync(
        string username,
        CancellationToken cancellationToken = default);

    Task<bool> InizializzaPasswordAdminAsync(
        string username,
        string passwordHash,
        CancellationToken cancellationToken = default);
}

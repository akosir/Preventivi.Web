namespace Preventivi.Core.RichiesteClienti;

using global::Preventivi.Core.Preventivi;

public interface IRichiestaClienteApplicationService
{
    Task<int> CreaAsync(
        RichiestaClienteCreateModel richiesta,
        CancellationToken cancellationToken = default);

    Task AggiornaAsync(
        RichiestaClienteUpdateModel richiesta,
        CancellationToken cancellationToken = default);

    Task AnnullaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default);

    Task RiattivaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default);

    Task<int> CreaPreventivoAsync(
        PreventivoCreateModel preventivo,
        string utente,
        CancellationToken cancellationToken = default);
}

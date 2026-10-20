namespace Preventivi.Core.Preventivi.Eliminazione;

public interface IPreventivoEliminazioneService
{
    Task EliminaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        CancellationToken cancellationToken = default);
}

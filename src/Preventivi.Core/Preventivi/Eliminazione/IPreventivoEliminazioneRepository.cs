namespace Preventivi.Core.Preventivi.Eliminazione;

public interface IPreventivoEliminazioneRepository
{
    Task<IReadOnlyList<AllegatoEliminazionePreventivo>> PreparaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        CancellationToken cancellationToken = default);

    Task EliminaAsync(
        TipoEliminazionePreventivo tipo,
        int idEntita,
        IReadOnlyCollection<int> idAllegatiAttesi,
        CancellationToken cancellationToken = default);
}

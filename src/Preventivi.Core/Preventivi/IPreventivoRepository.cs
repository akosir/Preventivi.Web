namespace Preventivi.Core.Preventivi;

public interface IPreventivoRepository
{
    Task<IReadOnlyList<PreventivoListItem>> GetElencoAsync(
        CancellationToken cancellationToken = default);

    Task<PreventivoDettaglio?> GetDettaglioAsync(
    int idPreventivo,
    CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PreventivoRigaListItem>> GetRigheAsync(
    int idPreventivo,
    CancellationToken cancellationToken = default);
}
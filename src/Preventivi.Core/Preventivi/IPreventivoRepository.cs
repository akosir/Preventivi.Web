namespace Preventivi.Core.Preventivi;

public interface IPreventivoRepository
{
    Task<IReadOnlyList<PreventivoListItem>> GetElencoAsync(
        CancellationToken cancellationToken = default);
}
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

    Task<PreventivoRigaDettaglio?> GetRigaAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default);

    Task<int> CreaRigaAsync(
        PreventivoRigaCreateModel riga,
        CancellationToken cancellationToken = default);

    Task EliminaRigaAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<TipoRigaPreventivoItem>> GetTipiRigaAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PreventivoVarianteItem>> GetVariantiAsync(
        int idPreventivo,
        CancellationToken cancellationToken = default);

    Task<PreventivoVarianteItem?> GetVarianteAsync(
        int idVariantePreventivo,
        CancellationToken cancellationToken = default);

    Task<int> CreaVarianteAsync(
        PreventivoVarianteCreateModel variante,
        CancellationToken cancellationToken = default);

    Task EliminaVarianteAsync(
        int idVariantePreventivo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PreventivoRigaComponenteItem>> GetComponentiAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default);

    Task<PreventivoRigaComponenteItem?> GetComponenteAsync(
        int idRigaCompPrev,
        CancellationToken cancellationToken = default);

    Task<int> CreaComponenteAsync(
        PreventivoRigaComponenteCreateModel componente,
        CancellationToken cancellationToken = default);

    Task EliminaComponenteAsync(
        int idRigaCompPrev,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PreventivoRigaMaterialeItem>> GetMaterialiAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default);

    Task<PreventivoRigaMaterialeItem?> GetMaterialeAsync(
        int idRigaMatPrev,
        CancellationToken cancellationToken = default);

    Task<int> CreaMaterialeAsync(
        PreventivoRigaMaterialeCreateModel materiale,
        CancellationToken cancellationToken = default);

    Task EliminaMaterialeAsync(
        int idRigaMatPrev,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<PreventivoRigaLavorazioneItem>> GetLavorazioniAsync(
        int idRigaPreventivo,
        CancellationToken cancellationToken = default);

    Task<PreventivoRigaLavorazioneItem?> GetLavorazioneAsync(
        int idRigaLavPrev,
        CancellationToken cancellationToken = default);

    Task<int> CreaLavorazioneAsync(
        PreventivoRigaLavorazioneCreateModel lavorazione,
        CancellationToken cancellationToken = default);

    Task EliminaLavorazioneAsync(
        int idRigaLavPrev,
        CancellationToken cancellationToken = default);
}

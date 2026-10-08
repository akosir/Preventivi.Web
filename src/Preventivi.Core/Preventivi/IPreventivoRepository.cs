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

    Task<IReadOnlyList<ArticoloLookupItem>> CercaArticoliAsync(
        string? ricerca,
        CancellationToken cancellationToken = default);

    Task<ArticoloLookupItem?> GetArticoloAsync(
        int idArticolo,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DistintaNodoLookupItem>> GetNodiDistintaAsync(
        int idArticolo,
        CancellationToken cancellationToken = default);

    Task<DistintaNodoLookupItem?> GetNodoDistintaAsync(
        int idNodoDistinta,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MaterialeLookupItem>> CercaMaterialiAsync(
        string? ricerca,
        CancellationToken cancellationToken = default);

    Task<MaterialeLookupItem?> GetMaterialeAnagraficaAsync(
        int idMateriale,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DistintaMaterialeLookupItem>> GetMaterialiDistintaAsync(
        int idNodoDistinta,
        CancellationToken cancellationToken = default);

    Task<DistintaMaterialeLookupItem?> GetMaterialeDistintaAsync(
        int idDistintaMateriale,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LavorazioneLookupItem>> CercaLavorazioniAsync(
        string? ricerca,
        CancellationToken cancellationToken = default);

    Task<LavorazioneLookupItem?> GetLavorazioneAnagraficaAsync(
        int idLavorazione,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DistintaLavorazioneLookupItem>> GetLavorazioniDistintaAsync(
        int idNodoDistinta,
        CancellationToken cancellationToken = default);

    Task<DistintaLavorazioneLookupItem?> GetLavorazioneDistintaAsync(
        int idDistintaLavorazione,
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
        int? idNodoDistinta,
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
        int? idNodoDistinta,
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

namespace Preventivi.Core.Anagrafiche;

public interface IAnagraficheProduttiveRepository
{
    Task<IReadOnlyList<UnitaMisuraLookupItem>> GetUnitaMisuraAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default);
    Task<IReadOnlyList<FornitoreAnagraficaLookupItem>> GetFornitoriAsync(
        int? idCorrente = null,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<MaterialeListItem>> GetMaterialiAsync(
        string? ricerca = null,
        bool? soloAttivi = null,
        string? tipoMateriale = null,
        CancellationToken cancellationToken = default);
    Task<MaterialeDettaglio?> GetMaterialeAsync(
        int idMateriale,
        CancellationToken cancellationToken = default);
    Task<int> CreaMaterialeAsync(MaterialeCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaMaterialeAsync(MaterialeUpdateModel modello, CancellationToken cancellationToken = default);
    Task ImpostaStatoMaterialeAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default);
    Task EliminaMaterialeAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LavorazioneListItem>> GetLavorazioniAsync(
        string? ricerca = null,
        bool? soloAttive = null,
        string? internaEsterna = null,
        CancellationToken cancellationToken = default);
    Task<LavorazioneDettaglio?> GetLavorazioneAsync(
        int idLavorazione,
        CancellationToken cancellationToken = default);
    Task<int> CreaLavorazioneAsync(LavorazioneCreateModel modello, CancellationToken cancellationToken = default);
    Task AggiornaLavorazioneAsync(LavorazioneUpdateModel modello, CancellationToken cancellationToken = default);
    Task ImpostaStatoLavorazioneAsync(AnagraficaProduttivaStatoModel modello, CancellationToken cancellationToken = default);
    Task EliminaLavorazioneAsync(AnagraficaProduttivaDeleteModel modello, CancellationToken cancellationToken = default);
}

using Preventivi.Core.Campionature;

namespace Preventivi.Data.Campionature;

public sealed class CampionaturaApplicationService : ICampionaturaApplicationService
{
    private readonly ICampionaturaRepository _repository;

    public CampionaturaApplicationService(ICampionaturaRepository repository)
    {
        _repository = repository;
    }

    public async Task<int> CreaAsync(
        CampionaturaCreateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        Normalizza(campionatura);
        Valida(campionatura);
        return await _repository.CreaAsync(campionatura, cancellationToken);
    }

    public async Task AggiornaAsync(
        CampionaturaUpdateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        Normalizza(campionatura);
        Valida(campionatura);

        if (campionatura.IdCampionatura <= 0)
            throw new ArgumentException("Campionatura non valida.");
        if (campionatura.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione della campionatura non valida.");

        await _repository.AggiornaAsync(campionatura, cancellationToken);
    }

    private static void Normalizza(CampionaturaCreateModel campionatura)
    {
        campionatura.Oggetto = campionatura.Oggetto.Trim();
        campionatura.DescrizioneCampione = Pulisci(campionatura.DescrizioneCampione);
        campionatura.Stato = campionatura.Stato.Trim();
        campionatura.Priorita = campionatura.Priorita.Trim();
        campionatura.Esito = Pulisci(campionatura.Esito);
        campionatura.Note = Pulisci(campionatura.Note);
        campionatura.Utente = campionatura.Utente.Trim();
    }

    private static void Valida(CampionaturaCreateModel campionatura)
    {
        if (campionatura.DataCampionatura == default)
            throw new ArgumentException("Inserire la data della campionatura.");
        if (campionatura.IdRichiestaCliente <= 0)
            throw new ArgumentException("Selezionare una richiesta cliente.");
        if (campionatura.IdVariantePreventivo.HasValue && !campionatura.IdPreventivo.HasValue)
            throw new ArgumentException("La variante richiede un preventivo collegato.");
        if (string.IsNullOrWhiteSpace(campionatura.Oggetto))
            throw new ArgumentException("Inserire l'oggetto della campionatura.");
        if (!CampionaturaValori.Stati.Contains(campionatura.Stato))
            throw new ArgumentException("Stato della campionatura non valido.");
        if (!CampionaturaValori.Priorita.Contains(campionatura.Priorita))
            throw new ArgumentException("Priorita della campionatura non valida.");
        if (campionatura.Esito is not null && !CampionaturaValori.Esiti.Contains(campionatura.Esito))
            throw new ArgumentException("Esito della campionatura non valido.");
        if (string.IsNullOrWhiteSpace(campionatura.Utente))
            throw new ArgumentException("Utente non disponibile.");
    }

    private static string? Pulisci(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}

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

        if (campionatura.Stato != "Aperta" ||
            campionatura.Esito is not null ||
            campionatura.DataConsegnaCampione.HasValue ||
            campionatura.DataChiusura.HasValue)
        {
            throw new ArgumentException(
                "Una nuova campionatura deve essere aperta e senza consegna effettiva, esito o data di chiusura.");
        }

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

    public async Task AggiornaStatoAsync(
        CampionaturaStatoUpdateModel campionatura,
        CancellationToken cancellationToken = default)
    {
        campionatura.Stato = campionatura.Stato.Trim();
        campionatura.Esito = Pulisci(campionatura.Esito);
        campionatura.Utente = campionatura.Utente.Trim();
        campionatura.MotivazioneCorrezione = Pulisci(campionatura.MotivazioneCorrezione);

        if (campionatura.IdCampionatura <= 0)
            throw new ArgumentException("Campionatura non valida.");
        if (!CampionaturaValori.Stati.Contains(campionatura.Stato))
            throw new ArgumentException("Stato della campionatura non valido.");
        if (campionatura.Esito is not null && !CampionaturaValori.Esiti.Contains(campionatura.Esito))
            throw new ArgumentException("Esito della campionatura non valido.");
        if (campionatura.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione della campionatura non valida.");
        if (string.IsNullOrWhiteSpace(campionatura.Utente))
            throw new ArgumentException("Utente non disponibile.");
        if (!campionatura.Amministratore && campionatura.MotivazioneCorrezione is not null)
            throw new ArgumentException("La motivazione e riservata alla correzione amministrativa.");
        if (campionatura.Stato == "Inviata al Cliente" && !campionatura.DataConsegnaCampione.HasValue)
            throw new ArgumentException("Indicare la data di consegna effettiva.");
        if (campionatura.Stato == "Approvata" &&
            campionatura.Esito is not ("Positivo" or "Positivo con modifiche"))
        {
            throw new ArgumentException("Per l'approvazione selezionare un esito positivo.");
        }
        if (campionatura.Stato == "Respinta" && campionatura.Esito != "Negativo")
            throw new ArgumentException("Una campionatura respinta richiede esito Negativo.");
        if (campionatura.Stato == "In Lavorazione" &&
            campionatura.Esito is not null and not "Da rifare")
        {
            throw new ArgumentException("Il ritorno in lavorazione ammette soltanto l'esito Da rifare.");
        }

        await _repository.AggiornaStatoAsync(campionatura, cancellationToken);
    }

    public async Task<int> CreaRilievoAsync(
        CampionaturaRilievoCreateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        NormalizzaRilievo(rilievo);
        ValidaRilievo(rilievo);

        return await _repository.CreaRilievoAsync(rilievo, cancellationToken);
    }

    public async Task AggiornaStatoRilievoAsync(
        CampionaturaRilievoStatoUpdateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        rilievo.Stato = rilievo.Stato.Trim();
        rilievo.Utente = rilievo.Utente.Trim();
        rilievo.MotivazioneCorrezione = Pulisci(rilievo.MotivazioneCorrezione);

        if (rilievo.IdRilievoCampionatura <= 0)
            throw new ArgumentException("Rilievo non valido.");
        if (!CampionaturaRilievoValori.Stati.Contains(rilievo.Stato))
            throw new ArgumentException("Stato del rilievo non valido.");
        if (rilievo.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");
        if (string.IsNullOrWhiteSpace(rilievo.Utente))
            throw new ArgumentException("Utente non disponibile.");

        if (!rilievo.Amministratore && rilievo.MotivazioneCorrezione is not null)
            throw new ArgumentException("La motivazione e riservata alla correzione amministrativa.");

        await _repository.AggiornaStatoRilievoAsync(rilievo, cancellationToken);
    }

    public async Task AggiornaRilievoAsync(
        CampionaturaRilievoUpdateModel rilievo,
        CancellationToken cancellationToken = default)
    {
        NormalizzaRilievo(rilievo);
        ValidaRilievo(rilievo);

        if (rilievo.IdRilievoCampionatura <= 0)
            throw new ArgumentException("Rilievo non valido.");
        if (rilievo.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");

        await _repository.AggiornaRilievoAsync(rilievo, cancellationToken);
    }

    public async Task EliminaRilievoAsync(
        CampionaturaRilievoDeleteModel rilievo,
        CancellationToken cancellationToken = default)
    {
        if (rilievo.IdRilievoCampionatura <= 0)
            throw new ArgumentException("Rilievo non valido.");
        if (rilievo.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");

        await _repository.EliminaRilievoAsync(rilievo, cancellationToken);
    }

    public async Task<int> CreaAdeguamentoAsync(
        CampionaturaAdeguamentoCreateModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        NormalizzaAdeguamento(adeguamento);

        if (adeguamento.IdRilievoCampionatura <= 0)
            throw new ArgumentException("Rilievo non valido.");
        if (adeguamento.VersioneRilievo.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");

        return await _repository.CreaAdeguamentoAsync(adeguamento, cancellationToken);
    }

    public async Task AggiornaAdeguamentoAsync(
        CampionaturaAdeguamentoUpdateModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        NormalizzaAdeguamento(adeguamento);

        if (adeguamento.IdAdeguamento <= 0)
            throw new ArgumentException("Adeguamento non valido.");
        if (adeguamento.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione dell'adeguamento non valida.");

        await _repository.AggiornaAdeguamentoAsync(adeguamento, cancellationToken);
    }

    public async Task EliminaAdeguamentoAsync(
        CampionaturaAdeguamentoDeleteModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        adeguamento.Utente = adeguamento.Utente.Trim();

        if (adeguamento.IdAdeguamento <= 0)
            throw new ArgumentException("Adeguamento non valido.");
        if (adeguamento.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione dell'adeguamento non valida.");
        if (adeguamento.VersioneRilievo.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");
        if (string.IsNullOrWhiteSpace(adeguamento.Utente))
            throw new ArgumentException("Utente non disponibile.");

        await _repository.EliminaAdeguamentoAsync(adeguamento, cancellationToken);
    }

    public async Task<int> PreparaAdeguamentoAsync(
        CampionaturaAdeguamentoPreparaModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        adeguamento.CodiceVariante = adeguamento.CodiceVariante.Trim();
        adeguamento.DescrizioneVariante = adeguamento.DescrizioneVariante.Trim();
        adeguamento.Utente = adeguamento.Utente.Trim();

        ValidaOperazioneAdeguamento(adeguamento.IdAdeguamento, adeguamento.VersioneRiga, adeguamento.Utente);
        if (string.IsNullOrWhiteSpace(adeguamento.CodiceVariante))
            throw new ArgumentException("Inserire il codice della variante.");
        if (string.IsNullOrWhiteSpace(adeguamento.DescrizioneVariante))
            throw new ArgumentException("Inserire la descrizione della variante.");

        return await _repository.PreparaAdeguamentoAsync(adeguamento, cancellationToken);
    }

    public async Task AnnullaPreparazioneAdeguamentoAsync(
        CampionaturaAdeguamentoAnnullaPreparazioneModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        adeguamento.Utente = adeguamento.Utente.Trim();
        ValidaOperazioneAdeguamento(adeguamento.IdAdeguamento, adeguamento.VersioneRiga, adeguamento.Utente);

        await _repository.AnnullaPreparazioneAdeguamentoAsync(adeguamento, cancellationToken);
    }

    public async Task ConfermaAdeguamentoAsync(
        CampionaturaAdeguamentoConfermaModel adeguamento,
        CancellationToken cancellationToken = default)
    {
        adeguamento.Utente = adeguamento.Utente.Trim();
        ValidaOperazioneAdeguamento(adeguamento.IdAdeguamento, adeguamento.VersioneRiga, adeguamento.Utente);
        if (adeguamento.VersioneRilievo.Length != 8)
            throw new ArgumentException("Versione del rilievo non valida.");

        await _repository.ConfermaAdeguamentoAsync(adeguamento, cancellationToken);
    }

    private static void NormalizzaRilievo(CampionaturaRilievoCreateModel rilievo)
    {
        rilievo.DescrizioneProblema = rilievo.DescrizioneProblema.Trim();
        rilievo.Gravita = rilievo.Gravita.Trim();
        rilievo.CausaPresunta = Pulisci(rilievo.CausaPresunta);
        rilievo.SoluzioneProposta = Pulisci(rilievo.SoluzioneProposta);
        rilievo.NoteCliente = Pulisci(rilievo.NoteCliente);
        rilievo.NoteInterne = Pulisci(rilievo.NoteInterne);
        rilievo.Utente = rilievo.Utente.Trim();
    }

    private static void ValidaRilievo(CampionaturaRilievoCreateModel rilievo)
    {
        if (rilievo.IdCampionatura <= 0)
            throw new ArgumentException("Campionatura non valida.");
        if (rilievo.DataRilevazione == default)
            throw new ArgumentException("Inserire la data del rilievo.");
        if (rilievo.IdTipoProblematica <= 0)
            throw new ArgumentException("Selezionare il tipo di problematica.");
        if (string.IsNullOrWhiteSpace(rilievo.DescrizioneProblema))
            throw new ArgumentException("Inserire la descrizione del problema.");
        if (!CampionaturaRilievoValori.Gravita.Contains(rilievo.Gravita))
            throw new ArgumentException("Gravita del rilievo non valida.");
        if (string.IsNullOrWhiteSpace(rilievo.Utente))
            throw new ArgumentException("Utente non disponibile.");
    }

    private static void NormalizzaAdeguamento(CampionaturaAdeguamentoCreateModel adeguamento)
    {
        adeguamento.DescrizioneAdeguamento = adeguamento.DescrizioneAdeguamento.Trim();
        adeguamento.Note = Pulisci(adeguamento.Note);
        adeguamento.Utente = adeguamento.Utente.Trim();

        if (string.IsNullOrWhiteSpace(adeguamento.DescrizioneAdeguamento))
            throw new ArgumentException("Inserire la descrizione dell'adeguamento.");
        if (string.IsNullOrWhiteSpace(adeguamento.Utente))
            throw new ArgumentException("Utente non disponibile.");
    }

    private static void NormalizzaAdeguamento(CampionaturaAdeguamentoUpdateModel adeguamento)
    {
        adeguamento.DescrizioneAdeguamento = adeguamento.DescrizioneAdeguamento.Trim();
        adeguamento.Note = Pulisci(adeguamento.Note);
        adeguamento.Utente = adeguamento.Utente.Trim();

        if (string.IsNullOrWhiteSpace(adeguamento.DescrizioneAdeguamento))
            throw new ArgumentException("Inserire la descrizione dell'adeguamento.");
        if (string.IsNullOrWhiteSpace(adeguamento.Utente))
            throw new ArgumentException("Utente non disponibile.");
    }

    private static void ValidaOperazioneAdeguamento(
        int idAdeguamento,
        byte[] versioneRiga,
        string utente)
    {
        if (idAdeguamento <= 0)
            throw new ArgumentException("Adeguamento non valido.");
        if (versioneRiga.Length != 8)
            throw new ArgumentException("Versione dell'adeguamento non valida.");
        if (string.IsNullOrWhiteSpace(utente))
            throw new ArgumentException("Utente non disponibile.");
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

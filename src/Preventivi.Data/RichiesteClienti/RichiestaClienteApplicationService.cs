using Preventivi.Core.RichiesteClienti;
using Preventivi.Core.Preventivi;

namespace Preventivi.Data.RichiesteClienti;

public sealed class RichiestaClienteApplicationService
    : IRichiestaClienteApplicationService
{
    private readonly IRichiestaClienteRepository _repository;

    public RichiestaClienteApplicationService(IRichiestaClienteRepository repository)
    {
        _repository = repository;
    }

    public async Task<int> CreaAsync(
        RichiestaClienteCreateModel richiesta,
        CancellationToken cancellationToken = default)
    {
        Normalizza(richiesta);
        Valida(
            richiesta.IdCliente,
            richiesta.Oggetto,
            richiesta.Stato,
            richiesta.Priorita,
            richiesta.InteresseCliente,
            richiesta.ProbabilitaChiusura,
            richiesta.Utente);

        return await _repository.CreaAsync(richiesta, cancellationToken);
    }

    public async Task AggiornaAsync(
        RichiestaClienteUpdateModel richiesta,
        CancellationToken cancellationToken = default)
    {
        Normalizza(richiesta);
        Valida(
            richiesta.IdCliente,
            richiesta.Oggetto,
            richiesta.Stato,
            richiesta.Priorita,
            richiesta.InteresseCliente,
            richiesta.ProbabilitaChiusura,
            richiesta.Utente);

        if (richiesta.VersioneRiga.Length != 8)
            throw new ArgumentException("Versione della richiesta non valida.");

        await _repository.AggiornaAsync(richiesta, cancellationToken);
    }

    public async Task AnnullaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default)
    {
        ValidaOperazioneStato(idRichiestaCliente, versioneRiga, utente);

        await _repository.AnnullaAsync(
            idRichiestaCliente,
            versioneRiga,
            utente.Trim(),
            cancellationToken);
    }

    public async Task RiattivaAsync(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente,
        CancellationToken cancellationToken = default)
    {
        ValidaOperazioneStato(idRichiestaCliente, versioneRiga, utente);

        await _repository.RiattivaAsync(
            idRichiestaCliente,
            versioneRiga,
            utente.Trim(),
            cancellationToken);
    }

    public async Task<int> CreaPreventivoAsync(
        PreventivoCreateModel preventivo,
        string utente,
        CancellationToken cancellationToken = default)
    {
        if (!string.Equals(preventivo.Origine, "Richiesta", StringComparison.Ordinal))
            throw new ArgumentException("Origine del preventivo non valida per la richiesta cliente.");
        if (preventivo.IdRichiestaCliente is null or <= 0)
            throw new ArgumentException("Selezionare una richiesta cliente valida.");
        if (string.IsNullOrWhiteSpace(utente))
            throw new ArgumentException("Utente non disponibile.");

        return await _repository.CreaPreventivoAsync(
            preventivo,
            utente.Trim(),
            cancellationToken);
    }

    private static void Normalizza(RichiestaClienteCreateModel richiesta)
    {
        richiesta.Oggetto = richiesta.Oggetto.Trim();
        richiesta.DescrizioneRichiesta = Pulisci(richiesta.DescrizioneRichiesta);
        richiesta.Stato = richiesta.Stato.Trim();
        richiesta.Priorita = richiesta.Priorita.Trim();
        richiesta.InteresseCliente = Pulisci(richiesta.InteresseCliente);
        richiesta.Note = Pulisci(richiesta.Note);
        richiesta.Utente = richiesta.Utente.Trim();
    }

    private static void Normalizza(RichiestaClienteUpdateModel richiesta)
    {
        richiesta.Oggetto = richiesta.Oggetto.Trim();
        richiesta.DescrizioneRichiesta = Pulisci(richiesta.DescrizioneRichiesta);
        richiesta.Stato = richiesta.Stato.Trim();
        richiesta.Priorita = richiesta.Priorita.Trim();
        richiesta.InteresseCliente = Pulisci(richiesta.InteresseCliente);
        richiesta.Note = Pulisci(richiesta.Note);
        richiesta.Utente = richiesta.Utente.Trim();
    }

    private static void Valida(
        int idCliente,
        string oggetto,
        string stato,
        string priorita,
        string? interesseCliente,
        int? probabilitaChiusura,
        string utente)
    {
        if (idCliente <= 0)
            throw new ArgumentException("Selezionare un cliente valido.");
        if (string.IsNullOrWhiteSpace(oggetto))
            throw new ArgumentException("Inserire l'oggetto della richiesta.");
        if (!RichiestaClienteValori.Stati.Contains(stato))
            throw new ArgumentException("Stato della richiesta non valido.");
        if (!RichiestaClienteValori.Priorita.Contains(priorita))
            throw new ArgumentException("Priorita della richiesta non valida.");
        if (interesseCliente is not null &&
            !RichiestaClienteValori.Interessi.Contains(interesseCliente))
            throw new ArgumentException("Interesse cliente non valido.");
        if (probabilitaChiusura is < 0 or > 100)
            throw new ArgumentException("La probabilita di chiusura deve essere compresa tra 0 e 100.");
        if (string.IsNullOrWhiteSpace(utente))
            throw new ArgumentException("Utente non disponibile.");
    }

    private static string? Pulisci(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static void ValidaOperazioneStato(
        int idRichiestaCliente,
        byte[] versioneRiga,
        string utente)
    {
        if (idRichiestaCliente <= 0)
            throw new ArgumentException("Richiesta cliente non valida.");
        if (versioneRiga.Length != 8)
            throw new ArgumentException("Versione della richiesta non valida.");
        if (string.IsNullOrWhiteSpace(utente))
            throw new ArgumentException("Utente non disponibile.");
    }
}

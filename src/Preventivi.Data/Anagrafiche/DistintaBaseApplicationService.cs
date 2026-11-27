using Microsoft.Extensions.Logging;
using Preventivi.Core.Allegati;
using Preventivi.Core.Allegati.Application;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Data.Anagrafiche;

public sealed class DistintaBaseApplicationService : IDistintaBaseApplicationService
{
    private readonly IDistintaBaseRepository _repository;
    private readonly IAllegatoRepository _allegati;
    private readonly IAllegatoApplicationService _allegatoApplicationService;
    private readonly ILogger<DistintaBaseApplicationService> _logger;

    public DistintaBaseApplicationService(
        IDistintaBaseRepository repository,
        IAllegatoRepository allegati,
        IAllegatoApplicationService allegatoApplicationService,
        ILogger<DistintaBaseApplicationService> logger)
    {
        _repository = repository;
        _allegati = allegati;
        _allegatoApplicationService = allegatoApplicationService;
        _logger = logger;
    }

    public Task<int> CreaBozzaAsync(
        DistintaRevisioneCreateModel modello,
        CancellationToken cancellationToken = default) =>
        _repository.CreaBozzaAsync(modello, cancellationToken);

    public Task ImportaAsync(
        DistintaImportazioneRequest request,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);
        if (request.IdImportazione == Guid.Empty || request.IdRevisioneDistinta <= 0 ||
            request.VersioneRiga.Length != 8 || request.Nodi.Count == 0 ||
            string.IsNullOrWhiteSpace(request.NomeFile) || request.NomeFile.Length > 260 ||
            !request.NomeFile.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase) ||
            string.IsNullOrWhiteSpace(request.ImprontaSha256) || request.ImprontaSha256.Length != 64 ||
            !request.ImprontaSha256.All(Uri.IsHexDigit) ||
            string.IsNullOrWhiteSpace(request.Utente) || request.Utente.Length > 256)
        {
            throw new ArgumentException("La richiesta di importazione non e valida.", nameof(request));
        }

        return _repository.ImportaAsync(request, cancellationToken);
    }

    public async Task<int> DuplicaAsync(
        DistintaRevisioneDuplicazioneRequest request,
        CancellationToken cancellationToken = default)
    {
        var sorgente = await _repository.GetRevisioneAsync(
            request.IdRevisioneSorgente,
            cancellationToken)
            ?? throw new KeyNotFoundException("La revisione sorgente non esiste.");

        if (!sorgente.Modificabile || sorgente.NumeroNodi == 0 ||
            sorgente.IdArticolo == request.IdArticoloDestinazione)
        {
            throw new DistintaBaseApplicationException(
                "Scegli una distinta corrente con componenti e un articolo di destinazione diverso.",
                new InvalidOperationException("Sorgente o destinazione non valida."));
        }

        var idRevisioneDestinazione = await _repository.CreaBozzaAsync(
            new DistintaRevisioneCreateModel
            {
                IdArticolo = request.IdArticoloDestinazione,
                Note = request.Note,
                Utente = request.Utente
            },
            cancellationToken);

        var allegatiCreati = new List<int>();

        try
        {
            var nodi = await _repository.GetNodiAsync(
                sorgente.IdRevisioneDistinta,
                cancellationToken);
            var mappaNodi = new Dictionary<int, int>();

            foreach (var nodo in nodi.OrderBy(x => x.Livello).ThenBy(x => x.OrdineVisualizzazione).ThenBy(x => x.IdNodoDistinta))
            {
                cancellationToken.ThrowIfCancellationRequested();
                int? idPadreDestinazione = nodo.IdNodoPadre.HasValue
                    ? mappaNodi[nodo.IdNodoPadre.Value]
                    : null;
                var idNodoDestinazione = await _repository.CreaNodoAsync(
                    new DistintaNodoCreateModel
                    {
                        IdArticolo = request.IdArticoloDestinazione,
                        IdRevisioneDistinta = idRevisioneDestinazione,
                        IdNodoPadre = idPadreDestinazione,
                        IdTipoNodo = nodo.IdTipoNodo,
                        CodiceNodo = nodo.CodiceNodo,
                        DescrizioneNodo = nodo.DescrizioneNodo,
                        QuantitaBase = nodo.QuantitaBase,
                        OrdineVisualizzazione = nodo.OrdineVisualizzazione,
                        Note = (await _repository.GetNodoAsync(nodo.IdNodoDistinta, cancellationToken))?.Note,
                        Utente = request.Utente,
                        ConsentiTipoNodoNonAttivo = true,
                        IdNodoRevisioneOrigine = sorgente.IdArticolo == request.IdArticoloDestinazione
                            ? nodo.IdNodoDistinta
                            : null
                    },
                    cancellationToken);
                mappaNodi.Add(nodo.IdNodoDistinta, idNodoDestinazione);

                await DuplicaAllegatiAsync(
                    AllegatoEntita.DistintaBaseNodi,
                    nodo.IdNodoDistinta,
                    idNodoDestinazione,
                    request.Utente,
                    allegatiCreati,
                    cancellationToken);

                foreach (var materiale in await _repository.GetMaterialiAsync(nodo.IdNodoDistinta, cancellationToken))
                {
                    var idMaterialeDestinazione = await _repository.CreaMaterialeAsync(
                        new DistintaMaterialeCreateModel
                        {
                            IdNodoDistinta = idNodoDestinazione,
                            IdMateriale = materiale.IdMateriale,
                            Quantita = materiale.Quantita,
                            CoeffScartoPerc = materiale.CoeffScartoPerc,
                            CostoUnitario = materiale.CostoUnitario,
                            Note = materiale.Note,
                            Utente = request.Utente,
                            ConsentiAnagraficaNonAttiva = true
                        },
                        cancellationToken);
                    await DuplicaAllegatiAsync(
                        AllegatoEntita.DistintaMateriali,
                        materiale.IdDistintaMateriale,
                        idMaterialeDestinazione,
                        request.Utente,
                        allegatiCreati,
                        cancellationToken);
                }

                foreach (var lavorazione in await _repository.GetLavorazioniAsync(nodo.IdNodoDistinta, cancellationToken))
                {
                    var idLavorazioneDestinazione = await _repository.CreaLavorazioneAsync(
                        new DistintaLavorazioneCreateModel
                        {
                            IdNodoDistinta = idNodoDestinazione,
                            IdLavorazione = lavorazione.IdLavorazione,
                            IdModelloCiclo = lavorazione.IdModelloCiclo,
                            Sequenza = lavorazione.Sequenza,
                            TempoSetupMin = lavorazione.TempoSetupMin,
                            TempoPezzoMin = lavorazione.TempoPezzoMin,
                            CostoOrario = lavorazione.CostoOrario,
                            CostoFisso = lavorazione.CostoFisso,
                            Note = lavorazione.Note,
                            Utente = request.Utente,
                            ConsentiAnagraficaNonAttiva = true
                        },
                        cancellationToken);
                    await DuplicaAllegatiAsync(
                        AllegatoEntita.DistintaLavorazioni,
                        lavorazione.IdDistintaLavorazione,
                        idLavorazioneDestinazione,
                        request.Utente,
                        allegatiCreati,
                        cancellationToken);
                }
            }

            foreach (var nodo in nodi.Where(x => !x.Attivo).OrderByDescending(x => x.Livello))
            {
                var idNodoDestinazione = mappaNodi[nodo.IdNodoDistinta];
                var dettaglio = await _repository.GetNodoAsync(idNodoDestinazione, cancellationToken)
                    ?? throw new InvalidOperationException("Il nodo duplicato non e stato trovato.");
                await _repository.ImpostaStatoNodoAsync(
                    new DistintaNodoStatoModel
                    {
                        IdNodoDistinta = idNodoDestinazione,
                        Attivo = false,
                        Utente = request.Utente,
                        VersioneRiga = dettaglio.VersioneRiga
                    },
                    cancellationToken);
            }

            var sorgenteAggiornata = await _repository.GetRevisioneAsync(
                sorgente.IdRevisioneDistinta, cancellationToken);
            if (sorgenteAggiornata is null ||
                !sorgenteAggiornata.VersioneRiga.SequenceEqual(sorgente.VersioneRiga))
            {
                throw new InvalidOperationException("La distinta sorgente è cambiata durante la copia. Ripetere la duplicazione.");
            }

            return idRevisioneDestinazione;
        }
        catch (Exception exception)
        {
            var erroriCompensazione = await CompensaAsync(
                idRevisioneDestinazione,
                allegatiCreati);
            if (erroriCompensazione.Count > 0)
            {
                _logger.LogCritical(
                    exception,
                    "Duplicazione distinta {IdRevisioneSorgente} fallita con compensazione incompleta sulla revisione {IdRevisioneDestinazione}.",
                    request.IdRevisioneSorgente,
                    idRevisioneDestinazione);
                throw new DistintaBaseApplicationException(
                    "La duplicazione non e riuscita e la pulizia della distinta incompleta richiede un intervento amministrativo.",
                    new AggregateException([exception, .. erroriCompensazione]));
            }

            throw new DistintaBaseApplicationException(
                "La duplicazione non e riuscita. La distinta incompleta e stata rimossa.",
                exception);
        }
    }

    private async Task DuplicaAllegatiAsync(
        string entita,
        int idSorgente,
        int idDestinazione,
        string utente,
        ICollection<int> allegatiCreati,
        CancellationToken cancellationToken)
    {
        foreach (var allegato in await _allegati.GetElencoAsync(entita, idSorgente, cancellationToken))
        {
            allegatiCreati.Add(await _allegatoApplicationService.DuplicaAsync(
                allegato.IdAllegato,
                entita,
                idDestinazione,
                utente,
                cancellationToken));
        }
    }

    private async Task<List<Exception>> CompensaAsync(
        int idRevisioneDistinta,
        IReadOnlyList<int> allegatiCreati)
    {
        var errori = new List<Exception>();
        foreach (var idAllegato in allegatiCreati.Reverse())
        {
            try
            {
                await _allegatoApplicationService.EliminaAsync(idAllegato, CancellationToken.None);
            }
            catch (Exception exception)
            {
                errori.Add(exception);
            }
        }

        try
        {
            await _repository.CompensaDuplicazioneAsync(idRevisioneDistinta, CancellationToken.None);
        }
        catch (Exception exception)
        {
            errori.Add(exception);
        }

        return errori;
    }
}

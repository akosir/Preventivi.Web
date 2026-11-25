using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Preventivi.Core.Anagrafiche;

namespace Preventivi.Data.Anagrafiche;

public sealed class ArticoliImportazioneService(
    IArticoliImportazioneRepository repository,
    ILogger<ArticoliImportazioneService> logger) : IArticoliImportazioneService
{
    public async Task<IReadOnlyList<ArticoliImportazioneErrore>> ValidaAsync(
        IReadOnlyList<ArticoloImportazioneRiga> righe, CancellationToken cancellationToken = default)
    {
        var errori = new List<ArticoliImportazioneErrore>();
        if (righe.Count == 0) errori.Add(new("Articoli", 0, "Righe", "Inserire almeno un articolo."));
        foreach (var riga in righe)
        {
            if (riga.RigaExcel < 2) errori.Add(new("Articoli", riga.RigaExcel, "Riga", "Numero riga Excel non valido."));
            Verifica(riga, "Codice articolo", riga.CodiceArticolo, 50, true, errori);
            Verifica(riga, "Descrizione", riga.Descrizione, 200, true, errori);
            Verifica(riga, "Versione articolo", riga.Versione, 20, false, errori);
            Verifica(riga, "Codice cliente", riga.CodiceCliente, 30, false, errori);
        }
        // Il database verifica i duplicati con la stessa collation dell'indice
        // univoco, compresi gli articoli non attivi, e i clienti ancora attivi.
        if (errori.Count == 0) errori.AddRange(await repository.ValidaAsync(righe, cancellationToken));
        return errori;
    }

    public async Task<int> ApplicaAsync(ArticoliImportazioneRequest richiesta, CancellationToken cancellationToken = default)
    {
        if (richiesta.IdImportazione == Guid.Empty ||
            string.IsNullOrWhiteSpace(richiesta.NomeFile) || richiesta.NomeFile.Length > 260 ||
            !richiesta.NomeFile.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase) ||
            string.IsNullOrWhiteSpace(richiesta.ImprontaSha256) || richiesta.ImprontaSha256.Length != 64 || !richiesta.ImprontaSha256.All(Uri.IsHexDigit) ||
            string.IsNullOrWhiteSpace(richiesta.Utente) || richiesta.Utente.Length > 256)
            throw new ArticoliImportazioneException("Dati di conferma non validi. Generare una nuova anteprima.");
        // La procedura ripete l'intera validazione nella transazione e registra
        // anche i rifiuti. Non usare un'anteprima precedente per autorizzare scritture.
        try
        {
            return await repository.ApplicaAsync(richiesta, cancellationToken);
        }
        catch (SqlException exception) when (exception.Number is >= 54601 and <= 54609 or 2601 or 2627 or 1205)
        {
            logger.LogWarning(exception, "Importazione articoli {Id} rifiutata", richiesta.IdImportazione);
            throw new ArticoliImportazioneException(exception.Number is >= 54601 and <= 54609
                ? exception.Message
                : "I dati sono cambiati durante l'importazione. Generare una nuova anteprima; nessun articolo e stato importato.");
        }
    }

    private static void Verifica(ArticoloImportazioneRiga riga, string campo, string? valore,
        int massimo, bool richiesto, ICollection<ArticoliImportazioneErrore> errori)
    {
        if (richiesto && string.IsNullOrWhiteSpace(valore))
            errori.Add(new("Articoli", riga.RigaExcel, campo, "Il valore e obbligatorio."));
        if (valore?.Length > massimo)
            errori.Add(new("Articoli", riga.RigaExcel, campo, $"Massimo {massimo} caratteri; il testo non viene troncato."));
    }
}

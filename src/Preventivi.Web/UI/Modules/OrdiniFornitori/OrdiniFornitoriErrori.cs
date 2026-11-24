using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace Preventivi.Web.UI.Modules.OrdiniFornitori;

public static class OrdiniFornitoriErrori
{
    public static bool Gestito(int numero) => numero is >= 54101 and <= 54129 or 547 or 2601 or 2627 or 8115;
    public static string Messaggio(int numero) => numero switch
    {
        54101 => "Compilare correttamente i campi obbligatori.",
        54102 => "Il fornitore selezionato non è attivo oppure non esiste.",
        54103 => "L’ordine non esiste più.",
        54104 => "L’ordine è stato modificato da un altro utente. Riaprire la pagina.",
        54105 => "L’operazione richiede un ordine in Bozza.",
        54106 => "La riga non appartiene all’ordine indicato.",
        54107 => "La riga è stata modificata da un altro utente. Riaprire la pagina.",
        54108 => "Il materiale o la lavorazione selezionati non sono disponibili.",
        54109 or 2601 or 2627 => "Il numero riga è già utilizzato nell’ordine.",
        54110 or 547 => "L’elemento ha riferimenti collegati. Consultare le dipendenze.",
        54111 or 8115 => "Quantità o prezzo producono un importo superiore ai limiti consentiti.",
        54112 => "La data ordine deve appartenere all’anno del numero già assegnato.",
        54122 => "L’ordine deve contenere almeno una riga Materiale o Lavorazione.",
        54123 => "Controllare descrizione, quantità e prezzo delle righe prima dell’invio.",
        54124 => "La riapertura richiede un ordine nello stato Inviato.",
        54125 => "L’ordine contiene ricezioni e non può essere riaperto.",
        54126 => "La motivazione amministrativa è obbligatoria.",
        54127 => "I documenti inviati sono conservati nello storico e non sono modificabili.",
        _ => "L’operazione sull’ordine non è consentita."
    };

    public static byte[] LeggiVersione(string? valore, ModelStateDictionary modelState)
    {
        try
        {
            var versione = Convert.FromBase64String(valore ?? string.Empty);
            if (versione.Length == 8) return versione;
        }
        catch (FormatException) { }
        modelState.AddModelError(string.Empty, "La versione dei dati non è valida. Riaprire la pagina.");
        return [];
    }
}

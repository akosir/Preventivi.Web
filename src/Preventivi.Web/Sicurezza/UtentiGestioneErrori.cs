using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace Preventivi.Web.Sicurezza;

public static class UtentiGestioneErrori
{
    public static bool Gestito(int numero) => numero is >=54301 and <=54311 or 2601 or 2627 or 1205;
    public static string Messaggio(int numero) => numero switch
    {
        54302 or 2601 or 2627 => "Lo username è già utilizzato.",
        54303 => "L’utente non esiste più.",
        54304 or 1205 => "I dati sono cambiati o un’altra modifica è in corso. Riaprire la pagina e riprovare.",
        54305 => "Selezionare ruoli attivi. Un ruolo non attivo già assegnato può essere conservato.",
        54306 => "Non è possibile disattivare il proprio account.",
        54307 => "Deve rimanere almeno un amministratore attivo con password impostata.",
        54308 => "L’operazione richiede un amministratore attivo. Accedere nuovamente.",
        54309 => "Impostare una password prima di attivare l’utente.",
        _ => "Verificare i dati obbligatori e selezionare almeno un ruolo."
    };
    public static byte[] Versione(string? valore,ModelStateDictionary modelState)
    {
        try { var bytes=Convert.FromBase64String(valore ?? ""); if(bytes.Length==8) return bytes; }
        catch(FormatException) { }
        modelState.AddModelError(string.Empty,"Versione dei dati non valida. Riaprire la pagina.");
        return [];
    }
}

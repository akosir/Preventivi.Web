namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class FornitoriSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 54001 and <= 54009 or 2601 or 2627 or 547;
    public static string Messaggio(int numero) => numero switch
    {
        54001 => "Compilare correttamente i campi obbligatori.",
        54002 or 2601 or 2627 => "Il codice fornitore è già utilizzato.",
        54003 => "Il fornitore non esiste più. Tornare all’elenco.",
        54004 => "Il fornitore è stato modificato da un altro utente. Riaprire la pagina.",
        54005 or 547 => "Il fornitore ha riferimenti collegati. Consultare le dipendenze e utilizzare Disattiva.",
        _ => "L’operazione sul fornitore non è consentita."
    };
}

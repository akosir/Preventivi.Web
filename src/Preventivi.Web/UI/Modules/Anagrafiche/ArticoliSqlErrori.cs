namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class ArticoliSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 53300 and <= 53349;

    public static string Messaggio(int numero) => numero switch
    {
        53301 => "Compilare correttamente tutti i campi obbligatori.",
        53302 => "Il codice articolo indicato e gia utilizzato.",
        53303 => "Selezionare un cliente valido e attivo.",
        53304 => "L'articolo non esiste.",
        53305 => "L'articolo e stato modificato da un altro utente. Ricaricare la pagina.",
        53306 => "L'articolo e utilizzato oppure contiene allegati e non puo essere eliminato. E possibile disattivarlo.",
        _ => "I dati dell'articolo non sono validi. Controllare i campi e riprovare."
    };
}

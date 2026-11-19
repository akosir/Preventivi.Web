namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class ModelliCicloSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 53500 and <= 53549;

    public static string Messaggio(int numero) => numero switch
    {
        53501 => "Compilare correttamente tutti i campi obbligatori.",
        53502 => "Il codice modello ciclo indicato e gia utilizzato.",
        53503 => "Il modello ciclo non esiste.",
        53504 => "Il modello ciclo e stato modificato da un altro utente. Ricaricare la pagina.",
        53505 => "Il modello ciclo contiene righe, allegati o riferimenti e non puo essere eliminato. E possibile disattivarlo.",
        53506 => "Il modello ciclo deve essere attivo per aggiungere nuove righe.",
        53507 => "Selezionare una lavorazione valida e attiva.",
        53508 => "Il numero riga indicato e gia utilizzato nel modello ciclo.",
        53509 => "La riga del modello ciclo non esiste.",
        53510 => "La riga e stata modificata da un altro utente. Ricaricare la pagina.",
        _ => "I dati del modello ciclo non sono validi. Controllare i campi e riprovare."
    };
}

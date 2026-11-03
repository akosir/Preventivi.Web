namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class AnagraficheSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 53100 and <= 53129;

    public static string Messaggio(int numero) => numero switch
    {
        53101 or 53111 => "Compilare tutti i campi obbligatori.",
        53102 => "Il codice indicato e gia utilizzato.",
        53113 => "La descrizione indicata e gia utilizzata.",
        53104 or 53114 => "L'elemento non esiste.",
        53105 or 53115 => "L'elemento e stato modificato da un altro utente. Ricaricare la pagina.",
        53106 => "L'unita di misura e utilizzata da uno o piu materiali e non puo essere eliminata. E possibile disattivarla.",
        53116 => "Il tipo nodo e utilizzato da una distinta e non puo essere eliminato. E possibile disattivarlo.",
        _ => "I dati non sono validi. Controllare i campi e riprovare."
    };
}

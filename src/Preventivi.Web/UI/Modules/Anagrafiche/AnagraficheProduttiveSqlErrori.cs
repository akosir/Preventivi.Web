namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class AnagraficheProduttiveSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 53200 and <= 53249;

    public static string Messaggio(int numero) => numero switch
    {
        53201 or 53221 => "Compilare correttamente tutti i campi obbligatori.",
        53202 or 53222 => "Il codice indicato e gia utilizzato.",
        53203 => "Selezionare un'unita di misura valida e attiva.",
        53204 or 53224 => "Selezionare un fornitore valido e attivo.",
        53205 => "Il fornitore predefinito e ammesso soltanto per un materiale gestito ad acquisto.",
        53206 or 53226 => "L'elemento non esiste.",
        53207 or 53227 => "L'elemento e stato modificato da un altro utente. Ricaricare la pagina.",
        53208 => "Il materiale e gia utilizzato e non puo essere eliminato. E possibile disattivarlo.",
        53223 => "La tipologia della lavorazione non e valida.",
        53225 => "Il fornitore predefinito e ammesso soltanto per una lavorazione acquistabile esternamente.",
        53228 => "La lavorazione e gia utilizzata e non puo essere eliminata. E possibile disattivarla.",
        _ => "I dati non sono validi. Controllare i campi e riprovare."
    };
}

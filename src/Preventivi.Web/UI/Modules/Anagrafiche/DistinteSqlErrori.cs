namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class DistinteSqlErrori
{
    public static bool Gestito(int numero) =>
        numero is >= 53400 and <= 53449 or >= 53600 and <= 53649 or >= 53700 and <= 53749;

    public static string Messaggio(int numero) => numero switch
    {
        53401 => "Compilare correttamente tutti i campi obbligatori.",
        53402 => "L'articolo indicato non esiste oppure non e attivo.",
        53403 => "Il tipo nodo selezionato non e valido o non e attivo.",
        53404 => "Il nodo padre non e valido o appartiene a un altro articolo.",
        53405 => "L'operazione creerebbe una gerarchia ciclica.",
        53406 => "Per l'articolo esiste gia un nodo radice attivo.",
        53407 => "L'elemento e stato modificato da un altro utente. Ricaricare la pagina.",
        53408 => "Il nodo non esiste.",
        53409 => "Il nodo contiene elementi attivi o riferimenti e non puo essere modificato in questo modo.",
        53410 => "Il materiale selezionato non e valido o non e attivo.",
        53411 => "Il materiale e gia presente sul nodo.",
        53412 => "La riga materiale non esiste.",
        53413 => "La lavorazione selezionata non e valida o non e attiva.",
        53414 => "La sequenza indicata e gia utilizzata sul nodo.",
        53415 => "La riga lavorazione non esiste.",
        53416 => "Rimuovere prima gli allegati associati all'elemento.",
        53601 => "Compilare correttamente tutti i campi obbligatori.",
        53602 => "L'articolo indicato non esiste oppure non e attivo.",
        53603 => "Per questo articolo esiste gia una distinta corrente.",
        53604 => "La motivazione amministrativa e obbligatoria.",
        53605 => "La revisione della distinta non esiste.",
        53606 => "La revisione selezionata non e una bozza modificabile.",
        53607 => "L'elemento e stato modificato da un altro utente. Ricaricare la pagina.",
        53608 => "La revisione deve contenere un nodo radice attivo prima della pubblicazione.",
        53609 => "La revisione non puo essere rimossa con questa operazione.",
        53610 => "Rimuovere prima gli allegati associati all'elemento.",
        53611 => "Il tipo nodo selezionato non e valido o non e attivo.",
        53612 => "Nella revisione esiste gia un nodo radice attivo.",
        53613 => "Il nodo padre non e valido o non e attivo.",
        53614 => "Il nodo non esiste.",
        53615 => "Il nodo non appartiene al contesto indicato.",
        53616 => "L'operazione creerebbe una gerarchia ciclica.",
        53617 => "Lo stato del nodo non e compatibile con la gerarchia.",
        53618 => "Il nodo contiene elementi o allegati e non puo essere eliminato.",
        53620 => "La procedura storica non e compatibile con le revisioni della distinta.",
        53621 => "Il materiale selezionato non e valido o non e attivo.",
        53622 => "Il materiale e gia presente sul nodo.",
        53623 => "La riga materiale non esiste.",
        53624 => "La lavorazione selezionata non e valida o non e attiva.",
        53625 => "La sequenza indicata e gia utilizzata sul nodo.",
        53626 => "La riga lavorazione non esiste.",
        53701 => "Compilare correttamente i dati dell'importazione.",
        53702 => "La revisione non esiste oppure non e una bozza modificabile.",
        53703 => "La revisione e stata modificata da un altro utente. Ricaricare la pagina.",
        53704 => "L'importazione e consentita soltanto su una revisione vuota.",
        53705 => "Questo file e gia stato importato nella revisione.",
        53706 => "La gerarchia dei nodi contenuta nel file non e valida.",
        53707 => "Il file contiene tipi nodo, materiali o lavorazioni non validi o non attivi.",
        53708 => "Il file contiene valori numerici, duplicati o riferimenti non validi.",
        _ => "L'operazione sulla distinta non e valida. Controllare i dati e riprovare."
    };
}

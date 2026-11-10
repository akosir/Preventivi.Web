namespace Preventivi.Web.UI.Modules.Anagrafiche;

public static class DistinteSqlErrori
{
    public static bool Gestito(int numero) => numero is >= 53400 and <= 53449;

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
        _ => "L'operazione sulla distinta non e valida. Controllare i dati e riprovare."
    };
}

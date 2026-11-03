# Anagrafiche

## Ambito corrente

TEC-016 introduce l'area Anagrafiche e il primo pacchetto composto da:

- unita di misura;
- tipi nodo distinta.

Il secondo pacchetto aggiunge:

- materiali;
- lavorazioni.

Entrambe le gestioni espongono ricerca per testo e stato, dettaglio, nuovo,
modifica, attivazione o disattivazione ed eliminazione controllata.

## Regole operative

- Un'unita di misura referenziata da `Materiali` non puo essere eliminata.
- Un tipo nodo referenziato da `DistintaBaseNodi` non puo essere eliminato.
- Gli elementi referenziati possono essere disattivati e restano disponibili
  nello storico.
- Modifica, stato ed eliminazione verificano `rowversion`.
- Creazione e modifica registrano utente e data.
- Un materiale puo indicare un fornitore predefinito soltanto se e gestito ad
  acquisto.
- Una lavorazione puo indicare un fornitore predefinito soltanto se e
  acquistabile esternamente.
- Costi e tempi sono valori predefiniti per i nuovi utilizzi e non modificano
  retroattivamente documenti o strutture esistenti.
- Materiali e lavorazioni referenziati da distinte, preventivi, modelli ciclo,
  associazioni fornitori, ordini o altri documenti collegati non possono
  essere eliminati e devono essere disattivati.

## Sicurezza

Le pagine richiedono il permesso `frmAnagrafiche`. Lo script TEC-016 crea la
voce autorizzativa e la assegna al ruolo `ADMIN`; l'estensione ad altri ruoli
deve essere esplicita.

## Database

Script incrementale:

`database/06_Aggiornamenti/TEC-016_01_Anagrafiche_Base.sql`

Versione prevista: `2026110301` (`TEC-016-ANAGRAFICHE-BASE`).

Secondo aggiornamento:

`database/06_Aggiornamenti/TEC-016_02_Materiali_Lavorazioni.sql`

Versione prevista: `2026110302` (`TEC-016-MATERIALI-LAVORAZIONI`).

Lo script e stato applicato dall'utente sull'ambiente di test il 3 novembre
2026 senza errori segnalati. Il collaudo applicativo e stato completato con
esito positivo per ricerca, creazione, modifica, audit, disattivazione,
riattivazione, eliminazione dei record non utilizzati e blocco dei record
referenziati da materiali o distinte base.

Il secondo aggiornamento e stato applicato dall'utente al database di test il
3 novembre 2026 senza errori segnalati. Non e stata eseguita una verifica
indipendente del registro `VersioniSchema`. Le gestioni Materiali e
Lavorazioni sono state collaudate dall'utente a runtime con esito positivo per
ricerca e filtri, creazione, modifica, audit, disattivazione, riattivazione,
eliminazione dei record non utilizzati e blocco dei record referenziati.

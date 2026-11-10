# Anagrafiche

## Ambito corrente

TEC-016 introduce l'area Anagrafiche e il primo pacchetto composto da:

- unita di misura;
- tipi nodo distinta.

Il secondo pacchetto aggiunge:

- materiali;
- lavorazioni.

Il terzo pacchetto aggiunge:

- articoli;
- allegati degli articoli mediante il modulo generico MB-01.

Il quarto pacchetto aggiunge:

- distinte base associate agli articoli;
- nodi gerarchici, materiali e lavorazioni della distinta;
- allegati di nodi, materiali e lavorazioni della distinta;
- report PDF scaricabile dell'esplosione della distinta.

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
- Un articolo puo essere associato facoltativamente a un cliente. In creazione
  e sostituzione il cliente deve essere attivo; un cliente disattivato dopo
  l'associazione resta visibile e conservabile.
- Le modifiche anagrafiche degli articoli non aggiornano retroattivamente
  preventivi, modelli o componenti esistenti.
- Un articolo referenziato da distinte, preventivi, modelli preventivo,
  componenti o allegati non puo essere eliminato e deve essere disattivato.
- Gli allegati articolo usano la chiave tecnica `Articoli` e devono essere
  eliminati esplicitamente prima dell'eventuale eliminazione fisica
  dell'articolo.
- Ogni articolo puo avere un solo nodo radice attivo. I figli devono
  appartenere allo stesso articolo, il livello e calcolato dal sistema e non
  sono ammessi cicli o figli attivi sotto un padre non attivo.
- Materiali e lavorazioni appartengono esclusivamente a un nodo. Costi, tempi,
  quantita e scarto sono valori copiati e modificabili nella distinta, senza
  aggiornamenti retroattivi.
- Nodi e righe di composizione verificano audit e `rowversion`. Non sono
  previste cancellazioni a cascata implicite.
- Gli allegati usano le chiavi tecniche `DistintaBaseNodi`,
  `DistintaMateriali` e `DistintaLavorazioni` e devono essere eliminati prima
  dell'elemento associato.
- Il report PDF della distinta espone gerarchia, quantita, materiali,
  lavorazioni e valori economici memorizzati. Non introduce formule di
  esplosione quantitativa o ricalcoli economici ulteriori.

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

Terzo aggiornamento:

`database/06_Aggiornamenti/TEC-016_03_Articoli_Allegati.sql`

Versione prevista: `2026110401` (`TEC-016-ARTICOLI-ALLEGATI`).

Quarto aggiornamento:

`database/06_Aggiornamenti/TEC-016_04_Distinte_Base.sql`

Versione prevista: `2026110501` (`TEC-016-DISTINTE-BASE`).

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

Il terzo aggiornamento e stato applicato dall'utente al database di test il 4
novembre 2026 senza errori segnalati. Non e stata eseguita una verifica
indipendente del registro `VersioniSchema`. La gestione Articoli e stata
collaudata a runtime con esito positivo per elenco, creazione, modifica,
audit, disattivazione, riattivazione, gestione completa degli allegati,
eliminazione dei record non utilizzati e blocco dei record referenziati.

Il quarto aggiornamento e stato applicato dall'utente al database di test il 6
novembre 2026 senza errori segnalati. Non e stata eseguita una verifica
indipendente del registro `VersioniSchema`. La gestione Distinte base e stata
collaudata a runtime con esito positivo per gerarchia, modifica, vincoli di
radice e ciclo, stati padre-figlio, materiali, lavorazioni, duplicati,
eliminazioni controllate e allegati separati per nodo, materiale e
lavorazione.

Il report PDF dell'esplosione distinta e predisposto nel repository e
collegato alla pagina di dettaglio della distinta. Generatore e impaginazione
multipagina sono stati verificati automaticamente e mediante rendering
grafico. Il 10 novembre 2026 l'utente ha completato con esito positivo il
collaudo runtime della nuova visualizzazione ad albero, del menu organizzato
secondo il flusso operativo e del download PDF con i dati del database di
test.

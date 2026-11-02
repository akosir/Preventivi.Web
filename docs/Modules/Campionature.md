# Campionature

**Stato:** TEC-014 chiusa per l'ambito base approvato.

Il modulo gestisce la testata delle campionature collegate alle richieste
clienti. Ogni campionatura appartiene a una richiesta; il collegamento a un
preventivo e a una sua variante e facoltativo.

## Funzioni disponibili

- elenco con filtri combinabili e stampa dei risultati;
- inserimento da elenco o dal dettaglio della richiesta cliente;
- dettaglio stampabile;
- modifica con controllo di concorrenza `rowversion`;
- aggiornamento dedicato dello stato con matrice operativa e audit delle
  correzioni amministrative;
- collegamenti alla richiesta, al preventivo e alla variante selezionati;
- allegati con inserimento, apertura, download ed eliminazione fisica;
- conteggio e alert operativi nella dashboard.

## Vincoli applicativi

- la richiesta cliente e obbligatoria;
- il preventivo, se indicato, deve appartenere alla richiesta;
- la variante, se indicata, deve appartenere al preventivo;
- il numero progressivo e annuale e viene assegnato dal database;
- l'anno della data non puo cambiare durante la modifica.

Gli allegati usano la chiave tecnica `Campionature` e il sistema MB-01. TEC-015
aggiunge al dettaglio della campionatura i rilievi qualitativi e gli
adeguamenti del preventivo proposti. Ogni rilievo e numerato progressivamente
nella campionatura e puo utilizzare una problematica standard coerente con il
tipo selezionato.

La registrazione di un adeguamento imposta il rilievo su `Soluzione Proposta`
e conserva il collegamento al preventivo e alla variante di origine, ma non
modifica righe, varianti o totali. L'applicazione economica avviene in due fasi
esplicite e richiede sia il permesso Campionature sia il permesso Preventivi.

`Prepara variante` crea una nuova variante senza modificare l'origine e clona
righe, componenti, materiali e lavorazioni rispettando identita e gerarchie
operative. Gli allegati non vengono copiati automaticamente. La preparazione
puo essere annullata prima della conferma: la variante generata viene
disattivata e l'adeguamento torna proposto.

`Conferma applicazione` ricalcola i dati della variante generata, registra
utente e data, rende storico l'adeguamento e porta il rilievo a `Risolto`. Gli
importi stimati dell'adeguamento restano valori di confronto. Dopo la conferma
l'applicazione e immutabile; una correzione richiede un nuovo adeguamento.

I rilievi non finali possono essere modificati; campionatura, numero e
identita restano invariati. Un rilievo puo essere eliminato soltanto quando e
`Aperto` e non possiede adeguamenti. Gli adeguamenti proposti possono essere
  modificati o eliminati, mentre quelli preparati devono prima annullare la
  preparazione e quelli applicati restano storici in sola lettura. Eliminando
  l'ultimo adeguamento, il rilievo non richiede piu
l'adeguamento del preventivo e torna da `Soluzione Proposta` a `In Analisi`.
Le operazioni applicano controlli di concorrenza `rowversion`.

## Workflow della campionatura

La creazione imposta sempre lo stato `Aperta`, senza esito, consegna effettiva
o data di chiusura. Questi dati non sono modificabili dalla maschera generica:
il dettaglio espone l'azione dedicata `Aggiorna stato`.

Le transizioni ordinarie consentite sono:

- `Aperta` -> `In Lavorazione` oppure `Annullata`;
- `In Lavorazione` -> `In Verifica` oppure `Annullata`;
- `In Verifica` -> `In Lavorazione`, `Inviata al Cliente` oppure `Annullata`;
- `Inviata al Cliente` -> `In Verifica`, `In Lavorazione`, `Approvata` oppure
  `Respinta`;
- `Approvata` o `Respinta` -> `Chiusa`.

Per gli operatori `Chiusa` e `Annullata` sono finali. Solo un amministratore
puo forzare una transizione o riaprire la campionatura, indicando una
motivazione registrata nell'audit. `Inviata al Cliente` richiede la consegna
effettiva; approvazione, rifiuto e chiusura richiedono rilievi conclusi e la
chiusura richiede anche l'assenza di adeguamenti non applicati. L'esito e
vincolato allo stato e la data di chiusura e gestita automaticamente.

## Workflow dei rilievi

Le transizioni ordinarie consentite sono:

- `Aperto` -> `In Analisi` oppure `Respinto`;
- `In Analisi` -> `Soluzione Proposta` oppure `Respinto`;
- `Soluzione Proposta` -> `In Analisi` oppure `Risolto`;
- `Risolto` -> `In Analisi` oppure `Chiuso`.

Per gli operatori `Respinto` e `Chiuso` sono stati finali. Solo un
amministratore puo eseguire una correzione esterna alla matrice o riaprire uno
stato finale; deve indicarne la motivazione e l'operazione viene conservata in
un audit dedicato con stato precedente, nuovo stato, utente e data.

Rilievi e adeguamenti dispongono di allegati MB-01 autonomi, rispettivamente
con le chiavi `CampionatureRilievi` e `CampionatureAdeguamenti`. Un elemento
con allegati non puo essere eliminato: gli allegati devono essere rimossi
esplicitamente prima dell'eliminazione del rilievo o dell'adeguamento.

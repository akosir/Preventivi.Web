# Campionature

Il modulo gestisce la testata delle campionature collegate alle richieste
clienti. Ogni campionatura appartiene a una richiesta; il collegamento a un
preventivo e a una sua variante e facoltativo.

## Funzioni disponibili

- elenco con filtri combinabili e stampa dei risultati;
- inserimento da elenco o dal dettaglio della richiesta cliente;
- dettaglio stampabile;
- modifica con controllo di concorrenza `rowversion`;
- collegamenti alla richiesta, al preventivo e alla variante selezionati;
- conteggio e alert operativi nella dashboard.

## Vincoli applicativi

- la richiesta cliente e obbligatoria;
- il preventivo, se indicato, deve appartenere alla richiesta;
- la variante, se indicata, deve appartenere al preventivo;
- il numero progressivo e annuale e viene assegnato dal database;
- l'anno della data non puo cambiare durante la modifica.

Rilievi, adeguamenti del preventivo, allegati e azioni dedicate di chiusura o
annullamento non fanno parte della gestione base TEC-014.

# Database

Questa cartella contiene l'intero schema SQL del progetto.

## Regole

- Ogni modifica deve avere il relativo script SQL.
- Gli script devono essere idempotenti quando possibile.
- Nessuna modifica al database deve rimanere solo sul server SQL.
- Tutto deve essere versionato tramite Git.

## Ordine di installazione

00_Installazione

01_Tabelle

02_Viste

03_StoredProcedure

04_Funzioni

05_DatiIniziali

06_Aggiornamenti
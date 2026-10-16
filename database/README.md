# Database

Questa cartella contiene la baseline dello schema SQL e gli aggiornamenti
versionati del progetto.

## Regole

- Ogni modifica deve avere il relativo script SQL.
- Gli script devono essere idempotenti quando possibile.
- Nessuna modifica al database deve rimanere solo sul server SQL.
- Tutto deve essere versionato tramite Git.

## Nuova installazione dello schema

Prerequisiti:

- SQL Server 2017 o versione successiva;
- database di destinazione vuoto, creato e selezionato prima dell'esecuzione;
- account con permessi di creazione degli oggetti nello schema `dbo`.

Eseguire nell'ordine:

1. `01_Tabelle/TEC-002_01_Tabelle.sql`;
2. `01_Tabelle/TEC-002_02_ChiaviEsterne.sql`;
3. `02_Viste/TEC-002_03_Viste.sql`;
4. `03_StoredProcedure/TEC-002_04_StoredProcedure.sql`.

La baseline TEC-002 rappresenta lo schema installato di
`PreventiviProduzione` al 16 ottobre 2026. Non contiene dati operativi,
utenti, ruoli, permessi, credenziali o backup. Non contiene neppure dati
iniziali: la creazione dello schema non rende quindi autonomamente
utilizzabile l'applicazione.

Il 16 ottobre 2026 l'ordine di installazione e stato collaudato su un
database temporaneo vuoto: creazione degli oggetti, verifica delle dipendenze
e `DBCC CHECKDB` sono terminati senza errori. Il database di collaudo e stato
eliminato al termine della verifica.

L'inventario degli oggetti e le impronte dei file estratti sono riportati in
`00_Installazione/TEC-002_Inventario.md`.

## Aggiornamento di un database esistente

Gli script storici nelle sottocartelle di `01_Tabelle` e
`03_StoredProcedure`, insieme agli script in `06_Aggiornamenti`, documentano
l'evoluzione di database esistenti. Devono essere selezionati in base alla
versione di partenza e non devono essere eseguiti indiscriminatamente dopo
la baseline TEC-002, che incorpora gia lo stato risultante al 16 ottobre
2026.

La baseline non contiene `USE` e non crea il database: la destinazione resta
una scelta esplicita dell'operatore.

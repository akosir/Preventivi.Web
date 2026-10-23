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

## Gestione modifiche Preventivi MB-02

Per abilitare le pagine di modifica di preventivo, riga, componente,
materiale e lavorazione su un database esistente, eseguire:

1. `06_Aggiornamenti/MB-02_01_Procedure_Aggiornamento_Preventivi.sql`.
2. `06_Aggiornamenti/MB-02_02_Modifica_Tipo_Riga.sql`.
3. `06_Aggiornamenti/MB-02_03_Modifica_Articolo_Riga.sql`.
4. `06_Aggiornamenti/MB-02_04_Costo_Riga_Articolo.sql`.
5. `06_Aggiornamenti/MB-02_05_Regole_Riga_Articolo.sql`.

Lo script aggiunge i lookup di modelli ciclo e fornitori, le procedure di
aggiornamento e il ricalcolo delle quantita gerarchiche dei componenti. Non
contiene `USE` e deve essere eseguito scegliendo esplicitamente il database
di destinazione.

Il secondo script consente di modificare il tipo della riga preventivo e
allinea la gestione del costo unitario libero al tipo selezionato.

Il terzo script espone le regole di visualizzazione dell'articolo e consente
di aggiornare articolo e modello ciclo quando previsti dal tipo riga.

Il quarto script esclude il costo unitario libero dalle righe che gestiscono
un articolo, anche quando il tipo mantiene il flag tecnico `RigaLibera`.

Il quinto script usa `RigaArticolo` come discriminante effettivo: il lookup
articolo e previsto solo per le righe articolo, mentre le righe libere
mantengono descrizione manuale e costo unitario obbligatorio.

## Sicurezza applicativa TEC-005

Per attivare l'autenticazione su un database esistente eseguire, dopo la
baseline o gli aggiornamenti applicabili:

1. `03_StoredProcedure/Sicurezza/TEC-005_01_Autenticazione.sql`;
2. inizializzare la prima password amministrativa con il comando locale
   documentato dall'applicazione;
3. creare, quando concordato con l'amministratore SQL, l'account a privilegi
   minimi mediante `00_Installazione/TEC-005_02_AccountApplicativo.sql` in
   modalita SQLCMD e aggiornare la configurazione esterna della connessione.

Il secondo script non contiene password reali, non modifica login esistenti e
non deve essere eseguito senza una variabile `PreventiviWebPassword` fornita
dall'operatore. La rotazione della precedente credenziale SQL resta
un'operazione amministrativa separata e coordinata con gli altri eventuali
utilizzatori dell'account.

## Eliminazioni coordinate TEC-007

Per attivare le eliminazioni coordinate di righe, componenti, materiali,
lavorazioni e relativi allegati su un database esistente, dopo TEC-001 e
TEC-009 eseguire:

1. `06_Aggiornamenti/TEC-007_01_Eliminazioni_Gerarchia_Allegati.sql`.

Lo script crea il tipo tabellare usato per il controllo concorrente e le
procedure di preparazione e conferma dell'eliminazione. Non contiene `USE` e
deve essere eseguito scegliendo esplicitamente il database di destinazione.

## Creazione preventivo TEC-008

Per attivare il flusso Web di creazione libera, da richiesta cliente o da
modello preventivo, dopo TEC-001 e TEC-009 eseguire:

1. `06_Aggiornamenti/TEC-008_01_Creazione_Preventivo.sql`;
2. `06_Aggiornamenti/TEC-008_02_Vincolo_Cliente_Richiesta.sql`;
3. `06_Aggiornamenti/TEC-008_03_Tipo_Riga_Modelli.sql`;
4. `06_Aggiornamenti/TEC-008_04_Regole_Riga_Articolo_Modelli.sql`.

Lo script aggiunge i lookup di richieste e modelli e la procedura
transazionale che assegna il numero progressivo annuale. Non contiene `USE`,
non modifica i preventivi esistenti e deve essere eseguito scegliendo
esplicitamente il database di destinazione.

Il secondo script allinea anche i database che avevano gia ricevuto TEC-008:
il cliente viene ereditato dalla richiesta e, se assente o non attivo, la
creazione viene rifiutata senza consentirne la sostituzione.

Il terzo script assegna a ogni riga modello un tipo riga esplicito. La
migrazione automatica prosegue soltanto quando esiste un unico tipo attivo
compatibile; in caso contrario mostra le righe da classificare e si interrompe
prima di applicare `NOT NULL`, chiave esterna e nuove procedure. Dopo la
classificazione manuale lo stesso script deve essere rieseguito.

Il quarto script riallinea le procedure di creazione da modello alla regola
`RigaArticolo`, mantenendo il costo unitario libero solo per i tipi liberi.

Per predisporre il solo modello tecnico usato nel collaudo controllato, dopo
gli aggiornamenti precedenti eseguire separatamente:

1. `06_Aggiornamenti/TEC-008_05_Modello_Collaudo_Articolo.sql`.

Questo script dati usa il tipo `ART` e l'articolo `GAB.01.001`, non crea alcun
preventivo e non modifica modelli con codici diversi da `TEST-TEC008-ART`.

## Correzione procedure varianti TEC-009

Sui database che hanno gia ricevuto TEC-009, applicare:

1. `06_Aggiornamenti/TEC-009_08_Correzione_QuotedIdentifier_Varianti.sql`.

Lo script ricrea le procedure di creazione, selezione ed eliminazione delle
varianti con `QUOTED_IDENTIFIER ON`, richiesto dall'indice filtrato che
garantisce una sola variante attiva selezionata per preventivo.

## Gestione modelli preventivo TEC-010

Per attivare la gestione Web dei modelli preventivo, dopo gli aggiornamenti
TEC-008 da `01` a `04`, eseguire:

1. `06_Aggiornamenti/TEC-010_01_Gestione_Modelli_Preventivo.sql`.

Lo script verifica preventivamente l'assenza di riferimenti orfani, completa
gli eventuali vincoli mancanti e crea le procedure per ricerca, testata, stato
e righe dei modelli. Non corregge automaticamente dati incoerenti, non elimina
modelli e non contiene `USE`.

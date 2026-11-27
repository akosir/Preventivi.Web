# Database

Questa cartella contiene la baseline dello schema SQL e gli aggiornamenti
versionati del progetto.

## Regole

### Correzione importazione Distinta e trigger — 27 novembre 2026

Applicare `06_Aggiornamenti/PFW_04_Importazione_Distinta_Trigger.sql` dopo
`2026112601`. Registra `2026112701`, codice `PFW-IMPORT-DISTINTE-TRIGGER`,
richiesto dall'applicazione aggiornata. Script predisposto, non applicato
dall'agente. Non rieseguire o modificare PFW_03 gia installato.

L'importazione mantiene il controllo della versione ricevuta e il blocco
UPDLOCK/HOLDLOCK della testata prima delle scritture. I trigger dei nodi e
degli elementi associati aggiornano la versione della testata nella stessa
transazione. L'aggiornamento finale dell'audit identifica quindi la testata
gia bloccata senza confrontarla con la versione precedente agli INSERT.
Restano verifica del conteggio aggiornato, rollback, registro esiti e blocchi
contro duplicati/importazioni concorrenti. Non cambia dati esistenti, trigger,
anagrafiche o preventivi. Riavviare l'app dopo lo script, generare una nuova
anteprima e collaudare conferma e valori salvati.

### Importazione Distinta corrente — Decisioni 387–391

Prima di utilizzare il codice aggiornato, applicare nel database di test
`06_Aggiornamenti/PFW_03_Importazione_Distinta_Corrente.sql`, dopo la versione
`2026112506`. Registra `2026112601`, codice `PFW-IMPORT-DISTINTE-CORRENTI`,
richiesto dal codice aggiornato. Non e stato applicato dall'agente.

Aggiorna Anagrafiche_Distinte_Importazioni_Applica. La destinazione deve
essere la distinta corrente vuota di un articolo attivo. La transazione
verifica versione, gerarchia, tipi nodo, materiali e lavorazioni attivi,
blocca le anagrafiche coinvolte fino al commit e verifica i conteggi inseriti.
Un errore annulla l'intera importazione. Non vengono sostituite strutture,
importati allegati o aggiornati preventivi.

DistinteBaseImportazioni e lo storico preesistente restano invariati.
Il nuovo registro DistinteBaseImportazioniEsiti conserva gli esiti dei nuovi
tentativi SQL, compresi i rifiuti dopo il rollback. Il trigger impedisce
modifica/cancellazione degli esiti. Non sono aggiunte FK dal registro al padre,
per non perdere lo storico quando una destinazione vuota viene rimossa.
Gli errori di caricamento o anteprima non scrivono nel database.

Verifiche locali: 403 test, ScriptDom su 3 batch e SHA-256 del payload.
Queste verifiche non attestano il database installato. Dopo lo script e
il riavvio, collaudare modello, anteprima completa, conferma, rifiuti e
concorrenza. Le riesecuzioni della migrazione con stessi metadati e impronta
non applicano modifiche. Lo script non seleziona il database.

```sql
SELECT IdImportazione, IdRevisioneDistinta, NomeFile, Utente, DataOperazione,
       Stato, NumeroNodi, NumeroMateriali, NumeroLavorazioni, Messaggio
FROM dbo.DistinteBaseImportazioniEsiti
ORDER BY IdEsito DESC;
```

### Importazione nuovi Articoli da Excel — Decisioni 382–386

Prima di utilizzare il codice aggiornato, eseguire nel database previsto
`06_Aggiornamenti/PFW_02_Importazione_Articoli.sql`, dopo `2026112505`.
Registra `2026112506`, codice `PFW-IMPORT-ARTICOLI`, ora richiesta dal codice.
Lo script e predisposto nel repository ma non applicato dall'agente.

L'utente ha successivamente confermato l'esecuzione dello script. Il registro
installato non e stato verificato dall'agente e il collaudo runtime
dell'importazione Articoli resta da eseguire.

Nuovi oggetti: ArticoliImportazioni (registro di completamenti e rifiuti),
indice univoco delle impronte completate, trigger di immutabilita,
Anagrafiche_Articoli_Importazione_Valida e _Applica. Nessuna anagrafica di prova,
nessun aggiornamento, riattivazione o eliminazione di articoli esistenti.
La migrazione e transazionale e la riesecuzione con stessa versione/impronta
non produce modifiche. Lo script non seleziona il database.

L'anteprima usa solo letture; l'applicazione ripete la validazione nella
transazione e controlla duplicati (inclusi i non attivi), limiti dei campi e
clienti attivi secondo le collation dei codici installati. sp_getapplock
serializza le importazioni; HOLDLOCK conserva i controlli fino al commit.
I rifiuti gestiti dalla procedura registrano l'esito dopo il rollback, con
zero articoli inseriti. Gli errori del caricamento Excel non scrivono nel DB.

Verifiche locali: 361 test complessivi, ScriptDom su 4 batch e SHA-256.
Non sono prove del database installato. Collaudo: Articoli → Importa Excel,
download modello, anteprima e conferma di nuovi articoli con/senza cliente;
duplicati nel file e nel DB, cliente non valido, lunghezze, variazioni dopo
l'anteprima e conferma ripetuta. Controllare il registro con:

```sql
SELECT IdImportazione, NomeFile, Utente, DataOperazione, Stato, NumeroArticoli, Messaggio
FROM dbo.ArticoliImportazioni
ORDER BY DataOperazione DESC;
```

### Controllo campi — Lunghezze testi, decisioni 377–381

Prima di avviare il codice aggiornato, applicare sul database previsto
`06_Aggiornamenti/PFW_01_Lunghezze_Testi.sql`. Richiede `2026112504`
(`TEC-019-UTENTI`) e registra `2026112505` (`PFW-LUNGHEZZE-TESTI`),
ora richiesta dall'applicazione. Lo script non e stato applicato dall'agente.

La migrazione allinea 20 parametri NVARCHAR in 7 procedure: Clienti_Crea,
Clienti_Aggiorna, Preventivi_Righe_Crea, Preventivi_Righe_Componenti_Crea,
Preventivi_Righe_Materiali_Crea, Preventivi_Righe_Lavorazioni_Crea e
Preventivi_Varianti_Crea. Non amplia le colonne e non modifica i dati.
Verifica i tipi e le lunghezze delle colonne sul database di destinazione,
accetta solo la dimensione precedente nota o quella corretta, conserva il
corpo delle procedure installate e modifica la dimensione della dichiarazione.
In caso di difformita annulla l'intera transazione e indica l'oggetto da
verificare. Sono necessari i permessi di lettura delle definizioni e ALTER.
Non rieseguire gli script storici dopo questa migrazione.

La riesecuzione con la stessa registrazione e impronta non applica modifiche.
Il controllo di versione impedisce l'uso operativo prima dell'aggiornamento.

Verifiche locali: ScriptDom sullo script e sulle due definizioni Clienti;
simulazione offline sui sorgenti di 20 parametri, 7 corpi procedura conservati
e 7 definizioni risultanti valide; SHA-256 del payload verificato. Queste
verifiche non costituiscono un'esecuzione SQL o un collaudo del database.

Collaudo dopo lo script: salvare e riaprire testi della lunghezza massima
in Clienti e nelle descrizioni di preventivo, riga, componente, materiale,
lavorazione e variante. Verificare anche messaggi e conservazione dei dati
con una richiesta oltre limite, in inserimento e modifica. Le maschere
limitano la digitazione; il controllo sul server deve operare anche quando
il limite HTML viene aggirato. Nessun testo deve essere troncato dal repository.

### TEC-019 — Gestione utenti ADMIN, decisioni 367–371

Dopo `2026112503`, eseguire nel database di test
`06_Aggiornamenti/TEC-019_01_Gestione_Utenti.sql`. Registra `2026112504`,
codice `TEC-019-UTENTI`, richiesto dall'applicazione aggiornata.
Lo script non è stato applicato dall'agente.

Estende UtentiApplicazione con VersioneRiga, VersioneSessione,
DataModifica e UtenteModifica. Crea UtentiGestioneAudit con trigger che
impedisce modifica/cancellazione dello storico. Aggiorna
Sicurezza_UtenteAccesso_Get e aggiunge Utenti_Gestione_VerificaAdmin,
Elenco, Dettaglio, Ruoli, Audit, Salva e Password. Le nuove procedure
Utenti_Gestione_* verificano l'attore ADMIN sul database.

La migrazione conserva username, password e ruoli esistenti; non inserisce
account di prova, credenziali predefinite o nuovi ruoli. Dopo l'aggiornamento
e l'avvio del codice aggiornato occorre accedere nuovamente, anche come
ADMIN, usando la password esistente. I nuovi cookie includono la versione
di sessione. L'applicazione controlla utenti, ruoli e permessi a ogni
richiesta autenticata e non applica migrazioni automaticamente.

Collaudi runtime da eseguire dopo lo script

1. Accesso ADMIN e collegamenti menu/dashboard. Accesso negato alle pagine
   e ai POST amministrativi con operatore, anche tramite URL diretto.
2. Creazione di un utente con password iniziale, ruolo attivo esplicito e
   username univoco; provare username duplicato e password non valide.
3. Modifica nome e ruoli, immutabilità dello username, concorrenza tra due
   modifiche e audit leggibile, senza password o hash nelle consultazioni.
4. Disattivazione di altro utente, perdita della sua sessione alla richiesta
   successiva, riattivazione e nuovo accesso; blocco dell'auto-disattivazione.
5. Con un solo ADMIN attivo, tentare di rimuovergli il ruolo ADMIN e
   verificare il blocco. Con due ADMIN, verificare modifiche concorrenti
   che non possano lasciare il sistema senza amministratori utilizzabili.
6. Reset password, invalidazione delle sessioni, rifiuto della vecchia
   password e accesso con la nuova. Verificare anche reset della propria
   password e successivo nuovo login.
7. Cambio ruoli mentre l'utente è collegato e revoca dell'accesso alla
   richiesta successiva; controllo del nuovo profilo dopo il login.
8. Conferme mancanti, annullamenti, versioni superate, audit conservato e
   rollback completo quando un salvataggio viene rifiutato.

### Variante scelta nella modifica

Dopo `2026112502`, eseguire nel database di test
`06_Aggiornamenti/TEC-009_11_Scelta_In_Modifica_Variante.sql`.
Installa `2026112503`, codice `TEC-009-VARIANTI-SCELTA`, richiesto
dall'applicazione aggiornata. Lo script non è stato applicato dall'agente.

Aggiorna `Preventivi_Varianti_Aggiorna` con il parametro obbligatorio
`@VarianteScelta`. Dati e scelta si salvano nella stessa transazione, con
ricalcolo del totale e rollback completo in caso di errore. Non modifica
tabelle o dati operativi durante l'installazione.

Collaudare caricamento della casella, sostituzione di una scelta esistente,
deselezione della variante scelta e totale delle sole righe comuni.
Lasciare deselezionata una variante diversa deve conservare l'altra scelta.
Verificare dati non validi, codice duplicato e salvataggio concorrente,
senza modifiche parziali ai dati o alla scelta.

### Completamento modifica varianti preventivo

Dopo `2026112501`, eseguire nel database di test
`06_Aggiornamenti/TEC-009_10_Modifica_Varianti.sql`. Registra
`2026112502`, codice `TEC-009-VARIANTI-MODIFICA`, richiesto
dall'applicazione aggiornata. Non è stato applicato dall'agente.

Aggiorna `Preventivi_Varianti_Dettaglio` e aggiunge
`Preventivi_Varianti_Aggiorna`, `Preventivi_Varianti_Righe` e
`Preventivi_Varianti_Righe_Crea`. Le tabelle e i dati operativi non sono
modificati dall'installazione. Il wrapper di creazione riga verifica
appartenenza, variante attiva e stato aperto del preventivo, poi richiama
la procedura corrente con l'associazione alla variante e il ricalcolo.

Collaudare modifica di codice, descrizione e note; codice duplicato;
blocco di salvataggi concorrenti; blocco di preventivo chiuso o variante
non attiva; appartenenza al preventivo. Nel dettaglio verificare solo le
righe della variante e aggiungerne una con Nuova riga, verificando totali,
associazione, accesso alla modifica e conservazione delle righe comuni.
Riprendere quindi il terzo collaudo del markup sulle varianti.

### Applicazione del markup alle righe esistenti

Dopo `2026112402`, eseguire nel database di test
`06_Aggiornamenti/TEC-009_09_Markup_Righe_Esistenti.sql`.
Registra `2026112501`, codice `TEC-009-MARKUP`, richiesto dall'applicazione
aggiornata. Lo script è incrementale, transazionale e ripetibile con gli
stessi metadati. Non è stato applicato dall'agente.

Crea `Preventivi_Markup_Impronta`, `Preventivi_Markup_Anteprima` e
`Preventivi_Markup_Applica`. Non cambia lo schema delle tabelle né i dati
operativi durante l'installazione. L'azione applicativa aggiorna la
percentuale predefinita e le righe automatiche in una transazione e
riutilizza il ricalcolo TEC-009 per righe, varianti e testata. Il prezzo
unitario e il markup delle righe manuali restano conservati.

Collaudi runtime da eseguire dopo lo script

1. Aprire un preventivo in Bozza e annotare vendita e prezzi manuali.
2. Aprire Applica markup alle righe esistenti, indicare una percentuale
   diversa, confermare e verificare i nuovi prezzi automatici, i margini
   e la conservazione delle righe manuali. La sola modifica del
   predefinito dalla normale pagina Modifica mantiene il comportamento
   precedente.
3. Verificare tutte le varianti e il totale della sola variante scelta,
   insieme alle righe comuni. Provare anche markup zero e preventivo
   senza righe.
4. Verificare che annullamento, conferma mancante, percentuale negativa o
   con più di due decimali non applichino modifiche.
5. Modificare una riga o il preventivo in un'altra scheda dopo l'apertura
   e verificare il rifiuto dell'anteprima superata. Verificare il blocco
   negli stati non aperti, anche con richiesta diretta.
6. Verificare il rollback completo quando un errore impedisce il
   ricalcolo. Gli ordini fornitori devono mantenere i propri prezzi.

### Generazione acquisti dai preventivi TEC-018, terzo pacchetto

Dopo `2026112401`, eseguire nel database di test
`06_Aggiornamenti/TEC-018_03_Generazione_Da_Preventivi.sql`.
Installa `2026112402`, codice `TEC-018-GENERAZIONE`, richiesto
dall'applicazione aggiornata. Lo script è transazionale e verificato
tramite impronta del payload. Non è stato applicato dall'agente.

Aggiunge alle righe ordine IdRigaMatPrev, IdRigaLavPrev e IdRigaCompPrev,
con FK e indici, e OrdiniFornitoriGenerazioni per riconoscere le richieste
già eseguite. Installa la funzione OrdiniFornitori_AcquistiPreventivo e le
procedure OrdiniFornitori_Generazione_Anteprima e
OrdiniFornitori_Generazione_Conferma. Aggiorna Salva, Righe_Salva, Elimina
e Righe_Elimina con serializzazione applicativa, conservando i controlli
di Bozza, audit, versioni e dipendenze.

I riferimenti degli ordini storici non sono ricostruiti per supposizione.
Un riferimento alla riga preventivo senza origine puntuale, compatibile
con l'elemento da acquistare, produce un avviso bloccante da riconciliare.
Nessun dato di prova è inserito e nessun valore del preventivo è aggiornato.

Collaudi runtime da eseguire dopo lo script

1. Aprire Genera ordini fornitori da preventivo e da singola riga.
2. Verificare flag di acquisto, componente, riga comune e variante.
3. Verificare fornitore suggerito attivo, scelta mancante e disattivato.
4. Selezionare materiali e lavorazioni di due fornitori e modificare
   quantità/prezzi. Confermare e verificare due nuove bozze, totali,
   riferimenti e conservazione dei valori del preventivo.
5. Riaprire l'anteprima e verificare gli impegni e il residuo. Ordinare
   parzialmente e completare il residuo. Bloccare gli eccessi.
6. Confermare due anteprime concorrenti e reinviare la stessa richiesta.
   Verificare assenza di duplicati, residuo e atomicità dei fornitori.
7. Modificare l'origine dopo l'anteprima e verificare il rifiuto della
   conferma. Riaprire l'anteprima per leggere i dati aggiornati.
8. Modificare quantità/prezzo della bozza generata, verificare il blocco
   degli aumenti oltre residuo e liberare l'impegno eliminando una riga.
9. Verificare avviso per ordini storici e conservazione delle origini
   referenziate. Verificare accesso con uno solo dei due permessi.

### Invio e storico ordini TEC-018, secondo pacchetto

Dopo `2026112302`, eseguire nel database di test
`06_Aggiornamenti/TEC-018_02_Invio_Documenti_Storici.sql`.
Installa `2026112401`, codice `TEC-018-INVIO`, richiesto
dall'applicazione aggiornata. Aggiunge DataInvio e UtenteInvio,
motivazione e stati nell'audit e OrdiniFornitoriDocumenti con copie
JSON immutabili. Le procedure confermano l'invio e riaprono in Bozza
con controlli di stato, concorrenza e ricezioni.

Il collaudo deve coprire ordine vuoto o con sole note, fornitore
disattivato, invio valido e totali, blocco delle modifiche dopo invio,
stampa dopo modifica dell'anagrafica del fornitore, riapertura
amministrativa motivata, seconda conferma con conservazione della prima
copia, concorrenza e permessi. Gli ordini precedenti privi di copia
storica restano consultabili con avviso nella stampa.

### Ordini fornitori TEC-018, primo pacchetto

Dopo la versione `2026112301`, eseguire sul database di test
`06_Aggiornamenti/TEC-018_01_Ordini_Fornitori_Bozza.sql`.
Registra la versione `2026112302`, codice `TEC-018-ORDINI-BOZZA`,
richiesta dall'applicazione aggiornata.

Lo script estende le tabelle esistenti con audit e rowversion, crea
OrdiniFornitoriAudit e OrdiniFornitoriProgressivi, installa le procedure
di gestione e attiva la voce menu `frmOrdiniFornitori`.
I permessi dei ruoli continuano a essere gestiti tramite MenuPermessiRuoli.
ADMIN dispone dell'accesso completo. Il pacchetto non inserisce ordini
di prova.

Collaudare creazione e numerazione, modifica della testata e delle righe,
materiali e lavorazioni da anagrafica o liberi, note a importo zero,
ricalcolo, concorrenza, stampa, allegati, eliminazione controllata,
filtri e accesso per profilo. Gli stati diversi da Bozza sono consultabili.

### Anagrafica Fornitori TEC-017

Dopo la versione `2026111901`, eseguire nel database di test
`06_Aggiornamenti/TEC-017_01_Anagrafica_Fornitori.sql`.
Registra `2026112301`, codice `TEC-017-FORNITORI`, richiesto
dall'applicazione aggiornata. Aggiunge audit e rowversion alla tabella
Fornitori, lo storico delle operazioni in FornitoriAudit, le procedure
di gestione e il controllo dell'esistenza del fornitore per gli allegati.
Lo script preserva i dati esistenti e non inserisce fornitori di prova.

Il collaudo deve coprire creazione, ricerca, modifica, concorrenza tra due
sessioni, disattivazione e riattivazione amministrative, selezioni dei
fornitori, eliminazione con e senza dipendenze, allegati e stampa filtrata.

### Convenzioni SQL

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

## Gestione anagrafiche TEC-016

Gli aggiornamenti devono essere applicati in ordine di versione. Dopo
`TEC-016_04_Distinte_Base.sql` (`2026110501`), la gestione Modelli ciclo
richiede:

1. `06_Aggiornamenti/TEC-016_05_Modelli_Ciclo.sql` (`2026111201`).
2. `06_Aggiornamenti/TEC-016_06_Distinte_Revisioni.sql` (`2026111202`).
3. `06_Aggiornamenti/TEC-016_07_Distinte_Importazione_Massiva.sql`
   (`2026111203`).

Lo script aggiunge audit e controllo di concorrenza a testata e righe,
installa le procedure operative e abilita gli allegati della testata. Non
applica automaticamente i modelli ciclo ai preventivi e non abilita
l'importazione massiva.

Il secondo script introduce testata e revisioni autonome delle distinte,
migra le distinte esistenti come revisione iniziale pubblicata, rende
immutabili le revisioni pubblicate e abilita la duplicazione completa in una
nuova bozza. Lo script disabilita esplicitamente le procedure storiche di
esplosione e rigenerazione, che non rispettano ancora il modello TEC-001.
L'applicazione delle revisioni ai preventivi resta fuori da questo
aggiornamento.

Il terzo script introduce i tipi tabellari, l'audit delle importazioni e la
procedura transazionale per importare nodi, materiali e lavorazioni da Excel.
L'operazione e ammessa soltanto su una revisione in bozza priva di nodi,
ricontrolla gerarchia, anagrafiche, duplicati e `rowversion` nel database e
rifiuta lo stesso SHA-256 nella medesima revisione. Gli allegati non vengono
importati.

## Gestione modifiche Preventivi MB-02

Per la decisione 335, dopo la versione `2026111203`, applicare in ordine
`TEC-016_08_Continuita_Nodi.sql`, `TEC-016_09_Snapshot_Iniziale.sql`,
`TEC-016_10_Anteprima_Snapshot.sql`, `TEC-016_11_Applica_Snapshot.sql` e
`TEC-016_12_Stato_Snapshot.sql` dalla cartella `06_Aggiornamenti`.
La versione finale è `2026111602`.

Per le decisioni 336–340, applicare sul database di test, nell'ordine:

1. `06_Aggiornamenti/TEC-016_13_Versione_Contenuto_Distinta.sql`.
2. `06_Aggiornamenti/TEC-016_14_Distinta_Corrente.sql`.
3. `06_Aggiornamenti/TEC-016_15_Avvisi_Distinta.sql`.
4. `06_Aggiornamenti/TEC-016_16_Aggiorna_Distinta.sql`.

La versione installata da questo gruppo di script è `2026111802`
(`TEC-016-AGGIORNA-DISTINTA`). Il passaggio archivia le vecchie bozze
di distinta e rende editabile la distinta corrente. Il collaudo deve
verificare il mantenimento dei dati, l'aggiornamento con ricalcolo su
preventivo e variante e il blocco in presenza di elementi da ricollocare.

Per ripristinare la duplicazione su altro articolo, applicare successivamente
`06_Aggiornamenti/TEC-016_17_Duplica_Distinta_Corrente.sql`.
La versione richiesta dall'applicazione è `2026111901`
(`TEC-016-DUPLICA-CORRENTE`). Lo script aggiunge la procedura di
compensazione delle copie incomplete. La destinazione deve essere un
articolo attivo senza distinta corrente. Il collaudo deve verificare
gerarchia, materiali, lavorazioni, stati e indipendenza degli allegati.

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

## Versionamento database TEC-012

Dopo avere applicato gli aggiornamenti richiesti fino a TEC-010, eseguire:

1. `06_Aggiornamenti/TEC-012_01_Versionamento_Database.sql`.

Lo script verifica gli oggetti applicativi richiesti, crea il registro
append-only `dbo.VersioniSchema`, crea la procedura
`dbo.Sistema_VersioneSchema_Corrente` e registra la baseline `2026102601`.
Non contiene `USE` e non applica automaticamente gli aggiornamenti precedenti.

Preventivi.Web accetta esclusivamente la versione database dichiarata nel
codice applicativo. Se il database non e disponibile, il registro non e
inizializzato o la versione e diversa, le funzioni operative restano bloccate
e viene mostrata la pagina di manutenzione. Dopo ogni aggiornamento database e
necessario riavviare l'applicazione; nessuna migrazione viene eseguita
automaticamente.

Ogni futuro script strutturale o funzionale deve essere transazionale,
incrementare la versione numerica `AAAAMMGGNN` e registrare in
`dbo.VersioniSchema` almeno codice intervento, nome script, descrizione,
impronta SHA-256, data UTC e operatore.

## Gestione Richieste Clienti TEC-013

Su un database allineato alla baseline `2026102601`, eseguire:

1. `06_Aggiornamenti/TEC-013_01_Gestione_Richieste_Clienti.sql`.
2. `06_Aggiornamenti/TEC-013_02_Riattivazione_Richieste_Clienti.sql`.

Lo script verifica il prerequisito, aggiorna `dbo.RichiesteClienti` con audit
e `rowversion`, crea le procedure di ricerca e gestione, protegge la
numerazione annuale e la creazione del preventivo collegato, quindi registra
la versione `2026102602` in `dbo.VersioniSchema`. L'intervento e
transazionale, non contiene `USE` e non elimina richieste esistenti.

Il secondo script richiede la versione `2026102602`, introduce la procedura
dedicata di riattivazione e registra la versione `2026102701`. Una richiesta
annullata torna allo stato `Nuova`; numero, prima attivazione, allegati e
documenti collegati restano invariati, mentre la data di chiusura viene
rimossa e l'audit di modifica viene aggiornato.

Prima dell'esecuzione verificare il database di destinazione e una copia di
sicurezza recuperabile. Dopo l'esecuzione riavviare Preventivi.Web e collaudare
il flusso completo; l'applicazione aggiornata richiede la versione
`2026102701` e blocca le funzioni operative finche entrambi gli script non
sono installati.

## Gestione base Campionature TEC-014

Su un database aggiornato alla versione `2026102701`, eseguire:

1. `06_Aggiornamenti/TEC-014_01_Gestione_Campionature.sql`.

Lo script aggiunge a `dbo.Campionature` l'audit applicativo e la colonna
`rowversion`, crea le procedure di elenco, dettaglio, lookup, inserimento e
modifica e registra la versione `2026102702` con codice `TEC-014-BASE`.
La numerazione annuale viene assegnata nella transazione di inserimento con un
lock applicativo dedicato. Preventivo e variante sono facoltativi, ma devono
appartenere rispettivamente alla richiesta e al preventivo selezionati.

Lo script e transazionale, non contiene `USE` e non modifica rilievi o
adeguamenti esistenti. Prima dell'esecuzione verificare il database di
destinazione e una copia di sicurezza recuperabile. L'applicazione aggiornata
richiede la versione `2026102902`.

## Rilievi e adeguamenti campionatura TEC-015

Su un database aggiornato alla versione `2026102702`, eseguire:

1. `06_Aggiornamenti/TEC-015_01_Rilievi_Adeguamenti_Campionature.sql`.
2. `06_Aggiornamenti/TEC-015_02_Modifica_Eliminazione_Rilievi_Adeguamenti.sql`.
3. `06_Aggiornamenti/TEC-015_03_Workflow_Stati_Allegati.sql`.
4. `06_Aggiornamenti/TEC-015_04_Applicazione_Adeguamenti.sql`.
5. `06_Aggiornamenti/TEC-015_05_Workflow_Stato_Campionature.sql`.

Lo script completa le tabelle esistenti dei rilievi e degli adeguamenti con
audit e `rowversion`, crea il vincolo di unicita del numero rilievo nella
campionatura e installa le procedure di elenco, dettaglio, lookup, inserimento,
aggiornamento stato e creazione dell'adeguamento. Registra la versione
`2026102901` con codice `TEC-015`.

Il secondo script richiede la versione `2026102901`, aggiunge l'audit di
modifica degli adeguamenti e installa le procedure di dettaglio, modifica ed
eliminazione controllata di rilievi e adeguamenti. Registra la versione
`2026102902` con codice `TEC-015-MODIFICA`.

Il terzo script richiede la versione `2026102902`, installa la matrice delle
transizioni di stato dei rilievi, l'audit delle correzioni amministrative e i
blocchi di eliminazione in presenza di allegati specifici. Registra la
versione `2026103001` con codice `TEC-015-WORKFLOW`. Le correzioni esterne alla
matrice sono riservate all'amministratore e richiedono una motivazione.

Il quarto script richiede la versione `2026103001`, separa la variante di
origine dalla variante generata e installa la preparazione, l'annullamento e la
conferma dell'applicazione economica. Registra la versione `2026103002` con
codice `TEC-015-APPLICAZIONE`. La preparazione clona righe, componenti,
materiali e lavorazioni senza copiare gli allegati; la conferma ricalcola la
variante generata e rende storico l'adeguamento.

Il quinto script richiede la versione `2026103002`, installa la matrice delle
transizioni della testata Campionatura, l'audit delle correzioni
amministrative e i controlli su consegna effettiva, esito, rilievi e
adeguamenti. Registra la versione `2026110201` con codice
`TEC-015-CAMPIONATURA-WORKFLOW`. La creazione parte sempre da `Aperta`; stato,
esito e date operative sono aggiornati soltanto dalla procedura dedicata.

Un rilievo e eliminabile soltanto quando e `Aperto` e senza adeguamenti; un
adeguamento applicato resta storico. L'eliminazione dell'ultimo adeguamento
riallinea il rilievo nella stessa transazione. Tutti gli script devono
essere eseguiti nell'ordine indicato.

La creazione dell'adeguamento non modifica automaticamente il preventivo o la
variante. Prima dell'esecuzione verificare che non esistano numeri rilievo
duplicati nella stessa campionatura e predisporre una copia di sicurezza
recuperabile. Dopo l'esecuzione riavviare l'applicazione e collaudare il flusso
dal dettaglio Campionatura.

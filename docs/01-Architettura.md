# 01 — Architettura di Preventivi.Web

## 1. Scopo, fonti e stato del documento

Questo documento descrive l’architettura di Preventivi.Web, distinguendo le decisioni approvate dall’implementazione corrente e dalle evoluzioni proposte.

Le indicazioni utilizzano queste categorie:

- **[D] Decisione approvata:** disposizione documentata nel repository o approvata esplicitamente e riportata in `AGENTS.md`.
- **[C] Implementazione verificata:** comportamento o struttura rilevati nel codice e negli script versionati.
- **[P] Proposta:** indicazione da valutare, non ancora equivalente a una decisione approvata.

### Riferimento dell’analisi

**[C]** Stato esaminato:

- Branch: `feature/workspace-preventivo`.
- Commit: `6fffb711fd44ee4ea3e8f815096cf66f9691f646`.
- Messaggio: `DOC-01 Aggiunte istruzioni condivise AGENTS.md`.

### Fonti

- `AGENTS.md`
- `README.md`
- `docs/08-Decisioni-Architetturali.md`
- `docs/03-Workspace.md`
- `database/README.md`
- `src/Preventivi.Web.slnx`
- Progetti, sorgenti e script SQL versionati.

**[C]** L’analisi è statica: documenta il contenuto del repository, senza attestare l’allineamento del database installato o il funzionamento completo dei flussi in esecuzione.

**[D]** Prima di modifiche architetturali o funzionali devono essere consultati `AGENTS.md`, il registro decisioni e la documentazione consolidata. Non si presume accesso automatico alle conversazioni ChatGPT o Work.

## 2. Architettura generale

**[D]** Preventivi.Web utilizza:

- ASP.NET Core;
- Razor Pages;
- SQL Server;
- ADO.NET;
- Bootstrap.

**[D]** Lo sviluppo prosegue esclusivamente sulla versione Web. Il frontend Access non deve essere ripreso senza richiesta esplicita.

**[C]** L’applicazione è organizzata in quattro progetti .NET, ospitati nella soluzione `src/Preventivi.Web.slnx`. Il progetto Web costituisce l’applicazione eseguibile; gli altri progetti sono librerie referenziate.

**[C]** Tutti e quattro i progetti utilizzano `net10.0`, nullable reference types e implicit usings.

**[C]** La presentazione è realizzata tramite Razor Pages. L’accesso ai dati utilizza `Microsoft.Data.SqlClient` e stored procedure. Gli allegati sono conservati su filesystem, con metadati in SQL Server.

```text
Browser
   |
ASP.NET Core / Razor Pages
   |
PageModel
   |----------------------------|
Servizi applicativi         Repository
   |                            |
   |----------------------------|
   |
ADO.NET / stored procedure
   |
SQL Server

Servizi allegati
   |
Filesystem
```

**[C]** Il livello dei servizi applicativi è presente solo in parte. Non esiste un passaggio obbligatorio attraverso un servizio applicativo per ogni pagina.

**[P]** Considerare il diagramma una rappresentazione dei percorsi attuali, non una dichiarazione di separazione completa già raggiunta.

## 3. Progetti: responsabilità e dipendenze

### 3.1 Preventivi.Core

**[C]** Contiene:

- modelli relativi a Clienti, Preventivi, Allegati e ParametriSistema;
- contratti dei repository;
- contratto `IAllegatoApplicationService`;
- richieste, risultati e opzioni dello storage;
- modelli di elenco, dettaglio, inserimento e lookup.

**[C]** I modelli comprendono dati e contratti utilizzati dall’applicazione. La presenza del progetto Core non dimostra che tutte le regole funzionali siano centralizzate al suo interno: parte dell’orchestrazione è nei PageModel e alcuni calcoli sono nelle stored procedure.

**[C]** Dipende da `Preventivi.Shared`.

### 3.2 Preventivi.Data

**[C]** Implementa:

- repository di Clienti, Preventivi, Allegati e ParametriSistema;
- creazione delle connessioni SQL;
- esecuzione dei comandi e mapping dei risultati;
- servizio applicativo degli allegati;
- servizio di storage su filesystem.

**[C]** L’infrastruttura comune è in `Comune`:

- `SqlConnectionFactory`;
- `DatabaseExecutor`;
- `DbMapper`.

**[C]** `IAllegatoStorageService` è attualmente dichiarata in Data, mentre i DTO dello storage e il contratto del servizio applicativo sono in Core.

**[C]** Dipende da `Preventivi.Core` e `Preventivi.Shared`.

### 3.3 Preventivi.Shared

**[C]** È referenziato dagli altri progetti e contiene predisposizioni per:

- Configuration;
- Constants;
- Extensions;
- Helpers;
- Security;
- Results.

**[C]** Nella baseline non risultano sorgenti applicativi versionati in questo progetto. Non devono essergli attribuite funzionalità di sicurezza, configurazione o gestione risultati già implementate.

**[P]** Inserire in Shared soltanto elementi effettivamente trasversali, evitando che diventi un contenitore indistinto di logica di dominio o presentazione.

### 3.4 Preventivi.Web

**[C]** Contiene:

- Razor Pages e relativi PageModel;
- layout e Partial;
- modelli UI;
- mapper di presentazione;
- ViewComponent e TagHelper;
- CSS, JavaScript e librerie frontend;
- configurazione dell’applicazione e dependency injection.

**[C]** Dipende da Core, Data e Shared.

### 3.5 Grafo delle dipendenze

```text
Web ──────> Core ──────> Shared
 │                         ▲
 ├────────> Data ───────────┤
 │            │            │
 │            └──> Core    │
 └─────────────────────────┘
```

**[P]** Conservare la direzione delle dipendenze. Non introdurre riferimenti da Core verso Data o Web.

**[P]** Un’eventuale revisione della collocazione dei servizi applicativi e dei contratti dello storage deve essere discussa esplicitamente; non è prevista implicitamente dalla descrizione di questa architettura.

## 4. Avvio e composizione dell’applicazione

**[C]** `Preventivi.Web/Program.cs` costituisce il punto di composizione.

Registra:

- Razor Pages;
- `SqlConnectionFactory` come singleton;
- `DatabaseExecutor` come scoped;
- repository come scoped;
- servizio applicativo e servizio storage degli allegati come scoped;
- binding della sezione `Storage` a `StorageOptions`.

**[C]** La connection string è letta dalla chiave `PreventiviDb`. Se assente, l’avvio genera un errore esplicito.

**[C]** La pipeline comprende HTTPS redirection, routing, authorization, static assets e Razor Pages.

**[C]** Fuori dall’ambiente Development viene configurato `UseExceptionHandler("/Error")`, insieme a HSTS.

**[C]** La presenza di `UseAuthorization()` non dimostra l’esistenza di un sistema completo di autenticazione e autorizzazione. Nel punto di composizione esaminato non è configurato un meccanismo di autenticazione.

**[P]** Separare la configurazione tecnica necessaria all’avvio dai parametri gestionali. La centralizzazione dei parametri gestionali in SQL Server non implica lo spostamento della connection string nel database stesso.

## 5. Organizzazione della presentazione

### 5.1 PFW — Preventivi Framework

**[D]** PFW separa:

- organizzazione del layout;
- navigazione;
- componenti grafici;
- logica applicativa.

**[D]** Il Layout Engine organizza l’applicazione. I componenti UI si occupano della rappresentazione grafica e non decidono il layout generale.

**[D]** L’Application Shell prevista comprende:

- Sidebar;
- Toolbar;
- Tabs;
- Workspace;
- StatusBar opzionale.

**[D]** I moduli devono essere ospitati nel Workspace. Sidebar e Workspace sono separati; la Sidebar prevista è gerarchica, con gruppi espandibili.

**[C]** I Partial PFW sono collocati in `Pages/Shared/PFW`, con componenti quali Badge, Button, EmptyState, KPI, Panel, Sidebar, Tabs, Toolbar e Workspace.

**[C]** I modelli corrispondenti sono organizzati sotto `UI/<Componente>`. Gli stili sono in `wwwroot/css/framework`.

**[C]** Il layout attuale `Pages/Shared/_Layout.cshtml` costruisce direttamente una shell con Sidebar, intestazione, contenuto e footer. Non compone integralmente la shell mediante i Partial PFW.

**[C]** Coesistono Partial, ViewComponent e TagHelper, inclusi più elementi relativi a Panel e PageHeader.

**[P]** Consolidare progressivamente la composizione, evitando nuove implementazioni equivalenti. La scelta dei Partial come componente base non equivale a un divieto documentato di utilizzare ViewComponent o TagHelper.

### 5.2 Common

**[C]** L’area Common della UI contiene il componente generico DataGrid:

- modello in `UI/Common/DataGrid`;
- rendering in `Pages/Shared/Common/_DataGrid.cshtml`;
- stylesheet in `wwwroot/css/common/datagrid.css`.

**[C]** La griglia rappresenta colonne, righe, celle, azioni e stato vuoto.

**[C]** `Common` della UI è distinto da `Preventivi.Data/Comune`, che contiene infrastruttura di accesso SQL.

**[P]** Mantenere Common indipendente dalle singole anagrafiche. La trasformazione dei dati di dominio in celle e azioni appartiene ai mapper o alla preparazione della presentazione.

### 5.3 Modules

**[C]** `UI/Modules` contiene modelli specifici di Allegati, Clienti e Dashboard.

**[C]** I Partial specifici si trovano nelle cartelle corrispondenti di `Pages/Shared`.

**[C]** Le pagine operative sono organizzate in `Pages/<Area>`. Il modulo Preventivi utilizza anche composizione diretta nelle pagine e non dispone di una struttura `UI/Modules/Preventivi` equivalente a quella dei Clienti.

**[P]** Non descrivere questa organizzazione come già uniforme per tutti i moduli.

### 5.4 Mappers

**[C]** `Mappers/Clienti/ClienteGridMapper.cs` converte gli elementi dell’elenco clienti in `DataGridModel`, definendo celle, badge e collegamenti.

**[C]** Questo mapping di presentazione è distinto dal mapping SQL:

- `DbMapper` associa colonne SQL a proprietà C# tramite reflection;
- `AllegatoMapper` esegue mapping esplicito dei risultati degli allegati;
- altri repository, come Clienti, contengono mapping direttamente nella propria implementazione.

**[P]** Mantenere separate trasformazioni SQL → modello e modello → UI.

## 6. Flussi applicativi e accesso ai dati

### 6.1 Modello di riferimento proposto

**[P]** Per operazioni con regole o coordinamento fra più risorse, il flusso di riferimento è:

```text
Razor Page / PageModel
        |
Servizio applicativo
        |
Repository
        |
ADO.NET / stored procedure
        |
SQL Server
```

**[P]** Ripartizione delle responsabilità:

- PageModel: input HTTP, binding, validazione di presentazione e risposta;
- servizio applicativo: coordinamento del caso d’uso;
- repository: accesso ai dati;
- SQL Server: persistenza e comportamento delle procedure;
- componenti Razor: rendering.

**[P]** L’estensione di questo modello a tutti i moduli è una proposta. Non risulta una decisione approvata che imponga già un servizio applicativo per ogni operazione.

### 6.2 Percorsi effettivamente implementati

| Ambito | Percorso verificato [C] |
|---|---|
| Clienti | PageModel → `IClienteRepository` → ADO.NET → stored procedure |
| Preventivi e dashboard principale | PageModel → `IPreventivoRepository` → `DatabaseExecutor` → stored procedure |
| Apertura e download allegati | PageModel → `IAllegatoApplicationService` → repository metadati e storage |
| Eliminazione allegati | PageModel → servizio applicativo → storage → repository |
| Inserimento allegati | PageModel → storage e repository, coordinati direttamente dalla pagina |
| Lettura parametri | Consumatore → `IParametriSistemaRepository` → stored procedure |
| Pagina diagnostica TestDb | PageModel → `SqlConnectionFactory` → apertura diretta della connessione |

**[C]** Il servizio applicativo degli allegati espone apertura ed eliminazione. L’upload non attraversa questo servizio.

**[C]** `PreventivoRepository` utilizza `DatabaseExecutor`; Clienti, Allegati e ParametriSistema costruiscono direttamente comandi ADO.NET usando `SqlConnectionFactory`.

**[C]** `DatabaseExecutor` apre una connessione per operazione. Non espone un coordinamento transazionale condiviso fra più chiamate repository.

**[P]** Evitare che la descrizione del flusso ideale nasconda queste differenze. La loro eventuale uniformazione deve essere trattata come intervento separato.

### 6.3 Contratti SQL e mapping

**[C]** I repository utilizzano stored procedure e parametri SQL.

**[C]** `DbMapper` associa i nomi delle colonne alle proprietà senza distinzione fra maiuscole e minuscole. Le colonne non corrispondenti e i valori `DBNull` vengono ignorati, lasciando i valori iniziali delle proprietà.

**[P]** Verificare esplicitamente i contratti fra procedure e modelli: un disallineamento può produrre valori predefiniti senza un errore immediato.

## 7. Parametri di sistema

**[D]** `dbo.ParametriSistema` è la fonte centralizzata dei parametri gestionali.

**[D]** Non devono essere aggiunti `DataUltimaModifica` e `UtenteUltimaModifica` a questa tabella.

**[C]** L’accesso è implementato da `IParametriSistemaRepository` e `ParametriSistemaRepository`.

**[C]** `GetValoreAsync` richiama `dbo.ParametriSistema_GetValore` e restituisce una stringa nullable.

**[C]** Lo script relativo a `TipoDato` prevede:

- Stringa;
- Intero;
- Decimale;
- Booleano;
- Data.

**[C]** Il repository non implementa un servizio generale di conversione tipizzata. La classe `ParametriSistema` presente in Core è attualmente vuota.

**[C]** Il parametro `PercorsoRootAllegati` è utilizzato dal servizio storage. Un valore mancante o vuoto genera un’eccezione.

**[P]** Per ogni nuovo parametro documentare significato, tipo, obbligatorietà, eventuale default approvato e comportamento in caso di valore non valido.

## 8. Allegati

### 8.1 Modello e associazioni

**[C]** Gli allegati sono associati alle entità mediante la coppia `Entita` e `IdEntita`.

Le chiavi utilizzate comprendono:

- `Clienti`;
- `Preventivi`;
- `PreventiviRigheComponenti`;
- `PreventiviRigheMateriali`;
- `PreventiviRigheLavorazioni`.

**[C]** SQL Server conserva i metadati; il filesystem conserva il contenuto dei file.

**[C]** L’organizzazione dello storage è:

```text
<root>/<Entita>/<anno>/<IdEntita>/<GUID><estensione>
```

**[C]** Il nome originale viene conservato separatamente dal nome archiviato.

### 8.2 Configurazione

**[C]** La root effettivamente utilizzata è letta da `PercorsoRootAllegati`.

**[C]** `StorageOptions.ArchivioAllegati` è ancora presente e registrato in `Program.cs`, ma non è la fonte utilizzata dal servizio storage attuale.

**[D]** La centralizzazione dei parametri gestionali resta la decisione di riferimento.

**[P]** Chiarire e consolidare i residui di configurazione senza introdurre fallback impliciti o cambiare le chiavi esistenti.

### 8.3 Upload

**[C]** Il PageModel `Allegati/Nuovo`:

1. valida i dati del form;
2. ricava il nome originale con `Path.GetFileName`;
3. copia il caricamento in un file temporaneo;
4. richiama lo storage;
5. registra i metadati tramite repository;
6. esegue il redirect;
7. rimuove il temporaneo nel blocco `finally`.

**[C]** La copia iniziale nel temporaneo precede il blocco `try/finally`. Un errore durante quella fase non è coperto dalla stessa pulizia.

**[C]** Non è presente una compensazione esplicita che elimini il file definitivo se la registrazione dei metadati fallisce.

### 8.4 Apertura, download ed eliminazione

**[C]** Apertura e download utilizzano il servizio applicativo per recuperare metadati e stream. Il tipo di contenuto viene determinato nella UI.

**[D]** L’eliminazione degli allegati consiste nella rimozione fisica del file e nella cancellazione definitiva del record da `dbo.Allegati`, in deroga alla disattivazione logica.

**[C]** Il servizio elimina prima il file e poi il record. Se il file non esiste, lo storage ritorna senza errore e il servizio può procedere alla cancellazione del record.

**[C]** Filesystem e SQL Server non sono coordinati da una transazione atomica. Se la cancellazione SQL fallisce dopo quella del file, può rimanere un record senza contenuto fisico.

**[P]** Definire gestione dei fallimenti parziali, controlli di appartenenza, limiti di upload e validazione dei percorsi. Non considerarli già completati.

## 9. Gerarchia funzionale dei preventivi

**[C]** La navigazione implementata segue questa struttura:

```text
Preventivo
├── Allegati della testata
├── Varianti
└── Righe
    └── Componenti
        ├── Allegati
        ├── Materiali
        │   └── Allegati
        └── Lavorazioni
            └── Allegati
```

**[C]** Il Workspace della riga carica preventivo, riga e componenti. Verifica anche che la riga appartenga al preventivo richiesto.

**[C]** Le pagine di dettaglio del componente caricano materiali, lavorazioni e allegati.

**[C]** Le origini previste dai flussi correnti sono:

| Elemento | Origini |
|---|---|
| Componente | Distinta, Articolo, Libero |
| Materiale | Distinta, Anagrafica, Libero |
| Lavorazione | Distinta, Anagrafica, Libero |

### 9.1 Associazione tecnica

**[C]** Materiali e lavorazioni sono associati mediante `IdRigaPreventivo` e `IdNodoDistinta`, che può essere nullo. Non utilizzano un riferimento diretto a `IdRigaCompPrev`.

**[C]** Le procedure di elenco confrontano il nodo, includendo esplicitamente il caso in cui entrambi i valori siano nulli.

**[C]** Ne consegue che componenti della stessa riga con lo stesso nodo, o senza nodo, possono riferirsi allo stesso insieme di materiali e lavorazioni. Il filtro non distingue autonomamente le singole istanze del componente.

**[P]** Formalizzare l’identità del componente operativo e l’associazione dei suoi elementi prima di modificare lo schema.

### 9.2 Calcoli presenti negli script

**[C]** Lo script del Workspace contiene calcoli in fase di inserimento:

- totale vendita riga: quantità × prezzo unitario, arrotondato a due decimali;
- margine valore: totale vendita − totale costi;
- margine percentuale: rapporto sul totale vendita, con gestione del totale zero;
- costo materiale: quantità × costo unitario, arrotondato a due decimali;
- tempo lavorazione: setup + tempo pezzo × quantità;
- costo lavorazione: tempo totale in ore × costo orario + costo fisso, arrotondato a due decimali.

**[C]** Questi sono comportamenti degli script versionati. Non costituiscono, da soli, una formalizzazione approvata dell’intero modello economico.

**[C]** Le procedure esaminate di inserimento materiali e lavorazioni non aggiornano esplicitamente i totali della riga, della variante o della testata.

**[P]** Definire regole di ricalcolo, propagazione, arrotondamento e responsabilità dei totali. Non presumere l’esistenza di trigger o meccanismi sul server non presenti nelle fonti verificate.

### 9.3 Eliminazioni e varianti

**[C]** Lo script versionato:

- elimina fisicamente una riga insieme a componenti, materiali e lavorazioni della riga;
- elimina un componente e materiali/lavorazioni individuati dalla coppia riga-nodo;
- elimina fisicamente singoli materiali e lavorazioni;
- disattiva una variante impostando `Attiva = 0`.

**[C]** Le procedure di eliminazione della gerarchia non coordinano esplicitamente la rimozione degli allegati dal filesystem.

**[P]** Non generalizzare la disattivazione logica o l’eliminazione fisica a tutte le entità. Formalizzare le regole delle singole operazioni e il trattamento degli allegati collegati.

## 10. Stato dei moduli

| Area | Stato verificato [C] |
|---|---|
| Clienti | Pagine e repository per elenco, dettaglio, inserimento, aggiornamento e disattivazione; integrazione allegati |
| Preventivi | Elenco, dettaglio e flussi per righe, componenti, materiali, lavorazioni e varianti; sviluppo ancora in corso |
| Allegati | Upload, apertura, download ed eliminazione implementati, con criticità di coordinamento e validazione |
| ParametriSistema | Lettura tramite repository; non risulta una UI gestionale dedicata |
| Dashboard principale | `/Index` utilizza i dati del repository preventivi |
| Dashboard precedente | `/Dashboard/Index` reindirizza alla principale; conserva codice demo |
| Richieste clienti | Pagina con contenuti dimostrativi e azioni non operative |
| Campionature | Pagina con contenuti dimostrativi e azioni non operative |
| Ordini | Non risulta un modulo operativo equivalente nelle pagine della soluzione |
| Articoli, materiali, lavorazioni | Lookup utilizzati dai preventivi; non equivalgono ad anagrafiche Web complete |
| Dev e TestDb | Pagine dimostrative o diagnostiche; non costituiscono una suite di test |

**[C]** Il riferimento a WMS e K-Count nel documento Workspace esprime il contesto di riutilizzo del framework; non dimostra che tali moduli siano implementati in questa applicazione.

## 11. Convenzioni e decisioni approvate

### 11.1 Framework

**[D]**

- Razor Partial come componente base.
- Model in italiano.
- Prefisso CSS `pfw-`.
- Sidebar gerarchica con gruppi espandibili.
- Separazione fra Sidebar e Workspace.
- Application Shell condivisa.
- Separazione fra Layout Engine e UI Components.
- Framework privo di logica di dominio.
- Preferenza per semplicità, leggibilità e coerenza.

**[C]** Il codice non è interamente allineato: sono presenti nomi UI inglesi, classi `app-*` e `workspace-*`, composizione diretta delle pagine e componenti alternativi.

**[P]** Affrontare questi scostamenti con interventi mirati, senza rinominare indiscriminatamente elementi esistenti.

### 11.2 Gestione degli errori

**[D]** Gli errori funzionali prevedibili devono essere intercettati nella UI e mostrati con messaggi comprensibili, senza Developer Exception Page o dettagli tecnici.

**[D]** Le eccezioni impreviste restano affidate al normale error handling e logging globale.

**[C]** Sono presenti validazioni `ModelState` e gestione dedicata di alcuni errori degli allegati, come il file mancante.

**[C]** La copertura non è uniforme: per esempio l’assenza di `PercorsoRootAllegati` genera un’eccezione non tradotta esplicitamente nei PageModel allegati esaminati.

**[C]** La pagina diagnostica `TestDb` espone `ex.Message`. Questo comportamento deve essere distinto dal trattamento previsto per la UI operativa.

### 11.3 SQL e documentazione

**[D]**

- Ogni modifica al database deve avere il relativo script nel repository.
- Nessuna modifica deve rimanere soltanto sul server.
- Gli script devono essere idempotenti quando possibile.
- Le nuove decisioni approvate devono essere registrate distinguendo decisioni, implementazioni e proposte.

**[C]** Le sei decisioni aggiunte durante la creazione di `AGENTS.md` sono presenti in quel file; il registro `docs/08-Decisioni-Architetturali.md` conserva ancora le precedenti decisioni PFW.

**[P]** Allineare successivamente il registro alle approvazioni già documentate, senza attribuire loro nuovi contenuti funzionali.

## 12. Criticità tecniche e aspetti da definire

### 12.1 Riproducibilità del database

**[C]** Tutte le 35 procedure richiamate da `PreventivoRepository` hanno una definizione negli script versionati. Molte sono raggruppate in `Preventivi_Schede_Workspace.sql`.

**[C]** Negli script `.sql` tracciati non sono presenti istruzioni `CREATE TABLE`: lo schema necessario a un’installazione da zero non è quindi rappresentato integralmente da questi script.

**[C]** Lo script del Workspace contiene `USE PreventiviProduzione`, che vincola esplicitamente il database di destinazione.

**[P]** Completare la documentazione di installazione, i prerequisiti e la copertura dello schema. Verificare sempre la destinazione prima dell’esecuzione.

### 12.2 Integrità della gerarchia

**[C]** I controlli di appartenenza non sono uniformi fra gli handler. Il POST di eliminazione componente richiama il repository con l’identificativo ricevuto senza ricaricare e verificare il componente nel contesto indicato.

**[C]** Il filtro riga-nodo può condividere materiali e lavorazioni fra più componenti e influenza anche le cancellazioni.

**[P]** Uniformare la verifica dell’intera catena Preventivo → Riga → Componente → Elemento e chiarire l’associazione univoca.

### 12.3 Transazioni e concorrenza

**[C]** Le procedure esaminate di eliminazione riga e componente eseguono più istruzioni senza una transazione esplicita al loro interno.

**[C]** La numerazione automatica della riga utilizza `MAX(RigaNr) + 1`, senza un coordinamento concorrente esplicito nello script.

**[P]** Verificare atomicità, vincoli e comportamento con richieste simultanee prima di considerare questi flussi consolidati.

### 12.4 Allegati e sicurezza

**[C]** Il servizio combina root e percorsi senza una verifica esplicita del percorso finale normalizzato rispetto alla root.

**[C]** Non è implementata una compensazione completa fra operazioni filesystem e SQL.

**[P]** Definire controlli sui percorsi, appartenenza e autorizzazioni, dimensioni, tipi di file e gestione degli orfani.

**[P]** Definire l’accessibilità delle pagine Dev e diagnostiche negli ambienti distribuiti.

### 12.5 Consolidamento UI

**[C]** Coesistono implementazioni PFW alternative e pagine dimostrative.

**[C]** Il layout referenzia CSS sotto `wwwroot/css/pages`, mentre i corrispondenti file versionati risultano sotto `Pages`. L’effettiva disponibilità degli asset richiede verifica in esecuzione.

**[P]** Consolidare shell, componenti e risorse statiche senza considerare i prototipi come funzionalità completate.

### 12.6 Servizi e regole funzionali

**[P]** Restano da definire:

- estensione e collocazione dei servizi applicativi;
- regole complete di ricalcolo e propagazione dei totali;
- comportamento delle varianti e della variante scelta;
- semantica delle cancellazioni nella gerarchia;
- trattamento degli allegati delle entità eliminate;
- validazione tipizzata dei parametri;
- strategia di autenticazione e autorizzazione.

### 12.7 Verifica e test

**[C]** Nella soluzione non risultano progetti di test automatizzati versionati.

**[P]** Prevedere verifiche mirate su gerarchia, calcoli, cancellazioni, errori prevedibili e consistenza degli allegati.

**[P]** La compilazione della soluzione verifica il codice, ma non attesta presenza e compatibilità delle procedure nel database installato.

**[P]** Le criticità descritte non autorizzano modifiche automatiche. Ogni evoluzione deve mantenere distinta la decisione approvata dalla proposta e dalla sua successiva implementazione.

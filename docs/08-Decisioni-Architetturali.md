# 08 — Registro delle decisioni architetturali

## 1. Scopo e classificazione

Il registro raccoglie le decisioni approvate di Preventivi.Web e mantiene separati i riscontri sull’implementazione e le proposte ancora da valutare.

- **[D] Decisione approvata:** disposizione già documentata come decisione o approvata esplicitamente.
- **[C] Implementazione o riscontro documentale:** descrizione dello stato rilevato, che non costituisce automaticamente una decisione.
- **[P] Proposta:** indicazione da valutare, priva di approvazione implicita.

L’inserimento di una descrizione tecnica nel repository non la trasforma automaticamente in una decisione approvata.

### Fonti del consolidamento

- `AGENTS.md`
- `README.md`
- `docs/01-Architettura.md`
- `docs/03-Workspace.md`
- Versione precedente di questo registro.
- `database/README.md`

**[C]** Il confronto documentale si riferisce al commit `26f32564bab9f62616cf4f3fe881b5dbfb97749d`, sul branch `feature/workspace-preventivo`.

**[C]** Le note sull’implementazione riprendono i riscontri documentati in `docs/01-Architettura.md`; non attestano lo stato del database installato.

### Identificativi e tracciabilità

**[P]** Conservare gli identificativi storici `Decisione 001–005`, `DA-009` e `DA-011`.

**[P]** Per le decisioni già approvate ma ancora assenti dal registro, utilizzare gli identificativi proposti `DA-012–DA-020`. L’assegnazione degli identificativi è editoriale; non rappresenta una nuova approvazione dei contenuti.

**[C]** Le fonti consultate non documentano decisioni corrispondenti ai numeri 006, 007, 008 e 010. Non viene ricostruito alcun contenuto per colmare questi intervalli.

**[C]** Le date originarie di approvazione delle decisioni storiche non sono riportate nel registro. I commit di documentazione non devono essere utilizzati automaticamente come date di approvazione.

## 2. Indice delle decisioni

Tutte le voci della tabella raccolgono contenuti già approvati o già classificati come decisioni nelle fonti.

| Identificativo | Oggetto | Provenienza |
|---|---|---|
| Decisione 001 | Razor Partial come componente base | Registro esistente |
| Decisione 002 | Model in italiano | Registro esistente |
| Decisione 003 | Prefisso CSS `pfw-` | Registro esistente |
| Decisione 004 | Sidebar gerarchica | Registro esistente |
| Decisione 005 | Separazione Workspace e Sidebar | Registro esistente |
| DA-009 | Application Shell | Registro esistente |
| DA-011 | Layout Engine e UI Components | Registro esistente |
| DA-012 | Tecnologie del progetto | README e AGENTS |
| DA-013 | Principi del Workspace e riutilizzabilità PFW | Workspace e AGENTS |
| DA-014 | Conservazione e organizzazione degli script SQL | Database README e AGENTS |
| DA-015 | Parametri gestionali centralizzati | Approvazione esplicita riportata in AGENTS |
| DA-016 | Eliminazione definitiva degli allegati | Approvazione esplicita riportata in AGENTS |
| DA-017 | Gestione degli errori funzionali | Approvazione esplicita riportata in AGENTS |
| DA-018 | Prosecuzione esclusivamente Web | Approvazione esplicita riportata in AGENTS |
| DA-019 | Continuità documentale | Approvazione esplicita riportata in AGENTS |
| DA-020 | Registrazione delle nuove decisioni | Approvazione esplicita riportata in AGENTS |
| DA-021 | Baseline completa dello schema SQL | Approvazione esplicita TEC-002 |
| DA-022 | Regole obbligatorie dell'interfaccia Preventivi | Approvazione esplicita nella sessione Work |
| DA-023 | Versionamento esplicito dello schema database | Approvazione esplicita nella sessione Work |
| DA-024 | Label funzionali leggibili | Approvazione esplicita nella sessione Work |
| DA-025 | Applicazione Android Preventivi Mobile | Approvazione esplicita nella sessione Work |

## 3. Decisioni storiche conservate

### Decisione 001 — Componente base PFW

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Il PFW utilizza Razor Partial come componente base.

**Fonte:** versione precedente di questo registro.

### Decisione 002 — Lingua dei Model

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

I Model sono in italiano.

**Fonte:** versione precedente di questo registro.

### Decisione 003 — Convenzione CSS

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Le classi CSS utilizzano prefisso `pfw-`.

**Fonte:** versione precedente di questo registro.

### Decisione 004 — Sidebar

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Sidebar gerarchica con gruppi espandibili.

**Fonte:** versione precedente di questo registro.

### Decisione 005 — Workspace e Sidebar

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Workspace separato dalla Sidebar.

**Fonte:** versione precedente di questo registro.

### DA-009 — Application Shell

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Il Preventivi Framework utilizza un’Application Shell composta da:

- Sidebar;
- Toolbar;
- Tabs;
- Workspace;
- StatusBar opzionale.

Tutti i moduli applicativi devono essere ospitati all’interno del Workspace.

L’Application Shell costituisce il layout standard del framework.

**Fonte:** versione precedente di questo registro.

### DA-011 — Layout Engine e UI Components

**Stato:** [D] Approvata, già presente nel registro.

**Decisione**

Il Preventivi Framework è suddiviso in due macro aree:

1. Layout Engine.
2. UI Components.

Il Layout Engine è responsabile esclusivamente dell’organizzazione dell’applicazione.

I Componenti UI sono responsabili esclusivamente della rappresentazione grafica.

Nessun componente UI può decidere il layout dell’applicazione.

**Fonte:** versione precedente di questo registro.

## 4. Decisioni già documentate da inserire nel registro

### DA-012 — Tecnologie del progetto

**Stato:** [D] Già documentata; identificativo proposto per il consolidamento.

**Decisione**

Preventivi.Web utilizza:

- ASP.NET Core;
- Razor Pages;
- SQL Server;
- ADO.NET;
- Bootstrap.

**Fonti**

- `README.md`, sezione Tecnologie.
- `AGENTS.md`, sezione 2.
- `docs/01-Architettura.md`, sezione 2.

**[C] Nota di delimitazione**

La versione .NET 10 è documentata come implementazione corrente. Non viene trasformata in un vincolo permanente attraverso questa decisione.

### DA-013 — Principi del Workspace e riutilizzabilità PFW

**Stato:** [D] Già documentata; identificativo proposto per il consolidamento.

**Decisione**

Il Workspace separa navigazione, layout, componenti grafici e logica applicativa.

I moduli forniscono dati e comportamenti, delegando al Workspace la costruzione dell’interfaccia utente.

L’Application Shell segue questi principi:

1. **Separazione delle responsabilità:** ogni componente svolge un solo compito.
2. **Componibilità:** ogni componente può contenere altri componenti.
3. **Riutilizzabilità:** il framework non contiene logiche di dominio.
4. **Coerenza:** ogni pagina utilizza lo stesso layout.
5. **Semplicità:** l’interfaccia privilegia leggibilità, velocità e chiarezza rispetto agli effetti grafici.

**Fonti**

- `docs/03-Workspace.md`, sezioni Scopo e Principi.
- `AGENTS.md`, sezioni 3 e 4.
- `docs/01-Architettura.md`, sezioni 5 e 11.

**Relazioni**

Integra DA-009 e DA-011 con i principi del Workspace. Non sostituisce né ridefinisce la composizione della shell o le responsabilità già registrate.

### DA-014 — Conservazione e organizzazione degli script SQL

**Stato:** [D] Già documentata; identificativo proposto per il consolidamento.

**Decisione**

Ogni modifica al database deve avere il relativo script SQL.

Nessuna modifica deve rimanere soltanto sul server SQL. Gli script devono essere conservati nel repository e versionati tramite Git.

Gli script devono essere idempotenti quando possibile.

L’organizzazione e l’ordine generale indicati dalla documentazione del database sono:

1. `00_Installazione`
2. `01_Tabelle`
3. `02_Viste`
4. `03_StoredProcedure`
5. `04_Funzioni`
6. `05_DatiIniziali`
7. `06_Aggiornamenti`

**Fonti**

- `database/README.md`.
- `AGENTS.md`, sezione 9.
- `docs/01-Architettura.md`, sezione 11.3.

**[C] Nota di delimitazione**

Questa decisione non attesta che lo schema sia già interamente riproducibile dagli script presenti.

**[P] Indicazione operativa già proposta**

Definire prerequisiti e sequenza dei singoli script. L’ordine delle categorie non equivale a un’autorizzazione a eseguire indiscriminatamente tutti i file.

### DA-015 — Parametri gestionali centralizzati

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

`dbo.ParametriSistema` è la fonte centralizzata dei parametri gestionali.

Non aggiungere `DataUltimaModifica` e `UtenteUltimaModifica` a `dbo.ParametriSistema`.

**Fonti**

- `AGENTS.md`, sezione 8.
- `docs/01-Architettura.md`, sezione 7.

**[C] Nota di implementazione**

La documentazione architetturale descrive la lettura tramite `IParametriSistemaRepository` e `dbo.ParametriSistema_GetValore`.

Il parametro utilizzato per la root degli allegati è `PercorsoRootAllegati`.

Questi dettagli implementativi non costituiscono ulteriori decisioni sul modello generale dei parametri.

### DA-016 — Eliminazione definitiva degli allegati

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

La gestione Allegati prevede:

- eliminazione fisica del file dallo storage;
- cancellazione definitiva del record da `dbo.Allegati`.

La decisione costituisce una deroga alla disattivazione logica.

**Fonti**

- `AGENTS.md`, sezione 7.
- `docs/01-Architettura.md`, sezione 8.4.

**[C] Nota di implementazione**

Il servizio corrente elimina prima il file e poi il record SQL. Questa sequenza è un comportamento implementato, non un’ulteriore decisione approvata sull’atomicità o sul recupero degli errori.

**[P] Ambiti ancora da definire**

Gestione dei fallimenti parziali e trattamento degli allegati collegati a entità eliminate nella gerarchia.

### DA-017 — Errori funzionali e gestione globale delle eccezioni

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

Gli errori funzionali prevedibili devono essere intercettati nella UI e mostrati con messaggi comprensibili, senza Developer Exception Page o dettagli tecnici.

Le eccezioni impreviste restano gestite dal normale error handling e logging globale.

**Fonti**

- `AGENTS.md`, sezione 5.
- `docs/01-Architettura.md`, sezione 11.2.

**[C] Nota di implementazione**

La documentazione architetturale rileva validazioni e intercettazioni già presenti, ma una copertura non uniforme dei casi prevedibili.

**[P] Ambito ancora da definire**

Completare la classificazione dei casi funzionali e il relativo trattamento nella UI senza introdurre intercettazioni generiche che nascondano errori imprevisti.

### DA-018 — Prosecuzione esclusivamente sulla versione Web

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

Proseguire esclusivamente sulla versione Web.

Non riprendere il frontend Access senza richiesta esplicita.

**Fonti**

- `AGENTS.md`, sezione 2.
- `docs/01-Architettura.md`, sezione 2.

### DA-019 — Continuità documentale e consultazione delle fonti

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

Prima di modifiche architetturali o funzionali, consultare:

- `AGENTS.md`;
- il registro decisioni;
- la documentazione consolidata del repository.

Non presumere accesso automatico alle chat ChatGPT o Work.

**Fonti**

- `AGENTS.md`, sezione 1.
- `docs/01-Architettura.md`, sezione 1.

### DA-020 — Registrazione delle nuove decisioni

**Stato:** [D] Approvata esplicitamente e riportata in AGENTS; identificativo proposto per il consolidamento.

**Decisione**

Documentare le nuove decisioni approvate nel registro decisioni del repository, distinguendo:

- decisioni;
- implementazioni;
- proposte.

**Fonti**

- `AGENTS.md`, sezione 12.
- `docs/01-Architettura.md`, sezione 11.3.

**Relazioni**

DA-019 disciplina la consultazione delle fonti prima delle modifiche. DA-020 disciplina la registrazione delle approvazioni. Le due decisioni hanno responsabilità distinte.

### DA-021 — Baseline completa dello schema SQL

**Stato:** [D] Approvata esplicitamente.

**Data di approvazione:** 16 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
a TEC-002.

**Decisione**

Versionare una baseline dell'intero schema installato del database, comprese
le aree applicative non ancora operative o funzionalmente congelate.

La baseline esclude:

- dati operativi e dati iniziali;
- utenti, ruoli e permessi del database;
- credenziali e stringhe di connessione;
- backup e altri contenuti contenenti dati.

**Relazioni**

La decisione attua DA-014 per la riproducibilita dello schema e non modifica
lo stato funzionale dei moduli rappresentati nel database.

**Riscontri [C] al 16 ottobre 2026**

La baseline TEC-002 e stata estratta in sola lettura dallo schema installato
di `PreventiviProduzione`. L'inventario comprende 49 tabelle, 517 colonne,
75 chiavi esterne, 26 viste e 74 stored procedure. I controlli statici
confermano inoltre 48 chiavi primarie, 161 default, 20 check e 101 strutture
indicizzate.

La baseline non contiene `USE`, dati o riferimenti di connessione. Il 16
ottobre 2026 e stata installata su un database temporaneo vuoto: i conteggi
degli oggetti sono risultati conformi, il refresh di viste e procedure e
`DBCC CHECKDB` sono terminati senza errori. Il database temporaneo e stato
eliminato e non risultano database TEC-002 residui sul server.

### DA-022 — Regole obbligatorie dell'interfaccia Preventivi

**Stato:** [D] Approvata esplicitamente.

**Data di approvazione:** 16 ottobre 2026.

**Fonte dell'approvazione:** richiesta esplicita nella sessione Work.

**Ambito**

Questa decisione deve essere consultata obbligatoriamente prima di creare o
modificare qualsiasi elemento della parte grafica dell'applicazione.

**Decisione**

Tutte le maschere e le pagine devono:

1. utilizzare i componenti UI appositamente realizzati per il progetto;
2. seguire il framework CSS del progetto presente in `wwwroot`;
3. nascere con l'insieme dei campi gia completo rispetto alla funzione
   concordata;
4. evidenziare graficamente i campi di testo obbligatori o richiesti;
5. fornire, per i campi identificativi dove necessario, un menu a tendina di
   lookup collegato alla rispettiva tabella;
6. esporre, salvo diverso accordo, le azioni `Nuovo`, `Modifica` ed `Elimina`
   tramite i componenti UI del progetto;
7. utilizzare label definite esplicitamente, leggibili e coerenti con il
   linguaggio funzionale, senza ricavarle automaticamente dai nomi delle
   proprieta C# o delle colonne SQL.

Ogni modulo esistente o nuovo deve disporre nella dashboard di un
collegamento alla propria gestione. Il collegamento deve puntare a una
gestione realmente esistente e raggiungibile: collegamenti fittizi o
segnaposto non soddisfano la decisione.

E inoltre approvata la realizzazione di:

- una pagina capace di ricercare dinamicamente nelle diverse anagrafiche,
  fra cui Preventivi, Lavorazioni e Materiali, con filtri avanzati e risultati
  stampabili;
- report stampabili dei preventivi differenziati in base all'uso successivo,
  compresa almeno la stampa delle sole righe destinate al cliente e la stampa
  interna per sezioni comprendente l'intero preventivo.

**Relazioni**

La decisione integra Decisione 001, Decisione 003, DA-009, DA-011 e DA-013.
Non modifica la separazione tra componenti UI, layout e logica di dominio.

**Riscontri [C] al 16 ottobre 2026**

La registrazione di questa decisione non attesta che tutte le pagine
esistenti siano gia conformi, ne che la ricerca dinamica e i report siano gia
implementati. La conformita deve essere verificata negli interventi grafici
successivi; ricerca e reportistica restano funzionalita approvate da
realizzare e collaudare.

### DA-023 — Versionamento esplicito dello schema database

**Stato:** [D] Approvata esplicitamente.

**Data di approvazione:** 21 ottobre 2026.

**Fonte dell'approvazione:** richiesta esplicita nella sessione Work.

**Contesto**

Gli script SQL sono conservati e versionati nel repository, ma questo non
identifica automaticamente la versione effettivamente installata su ciascun
database.

**Decisione**

Il database installato deve esporre una versione esplicita dello schema. Ogni
aggiornamento strutturale o funzionale deve essere riconducibile a una versione
ordinata e verificabile, in modo da determinare quali aggiornamenti risultano
applicati e quali restano da eseguire.

**Relazioni**

La decisione integra DA-014 e DA-021. Non sostituisce l'obbligo di conservare
gli script SQL nel repository.

**Riscontri [C] al 21 ottobre 2026**

La ricognizione del repository non ha individuato un meccanismo generale che
registri nel database la versione installata dello schema. I nomi progressivi
degli script e le verifiche dei singoli interventi non costituiscono da soli
un registro di versione del database.

**Risoluzione dei punti aperti [D] al 26 ottobre 2026**

Le decisioni 239-245, registrate nella sezione 5.16, definiscono il meccanismo
tecnico, la versione iniziale, la numerazione e il controllo applicativo. Lo
script iniziale e stato applicato e il collaudo runtime e stato completato il
26 ottobre 2026. La decisione DA-023 non presenta quindi punti funzionali
aperti per la baseline TEC-012.

### DA-024 — Label funzionali leggibili

**Stato:** [D] Approvata esplicitamente.

**Data di approvazione:** 21 ottobre 2026.

**Fonte dell'approvazione:** richiesta esplicita nella sessione Work.

**Decisione**

Le label dei campi nelle maschere e nelle pagine devono essere definite
esplicitamente con testo leggibile e coerente con il linguaggio funzionale.
Non devono essere esposte label ottenute automaticamente dai nomi tecnici
delle proprieta C# o delle colonne SQL.

**Relazioni**

La decisione integra DA-022 ed e obbligatoria per ogni nuova pagina o modifica
grafica. Non autorizza una revisione indiscriminata di pagine estranee
all'intervento corrente.

**Riscontri [C] al 21 ottobre 2026**

La registrazione della decisione non attesta che tutte le pagine esistenti
siano gia conformi. La conformita delle label deve essere verificata negli
interventi grafici successivi.

### DA-025 — Applicazione Android Preventivi Mobile

**Stato:** [D] Approvata esplicitamente per obiettivi, ambito della prima fase
e requisiti di utilizzo. Le scelte tecniche indicate nei punti aperti restano
[P].

**Data di approvazione:** 21 ottobre 2026.

**Fonte dell'approvazione:** richiesta esplicita nella sessione Work.

**Obiettivo**

Realizzare un'applicazione Android, denominata `Preventivi Mobile`, che renda
consultabili da qualsiasi luogo i dati gestiti dal sistema Preventivi.

**Prima fase [D]**

La prima fase e esclusivamente di consultazione e deve comprendere:

1. ricerca dei preventivi mediante filtri avanzati;
2. consultazione della testata e dei dettagli dei preventivi;
3. ricerca e consultazione dei clienti;
4. ricerca e consultazione delle tabelle anagrafiche piu importanti;
5. interfaccia ordinata, leggibile e progettata per una navigazione semplice
   su dispositivo mobile;
6. predisposizione architetturale delle future operazioni di inserimento,
   modifica ed eliminazione, senza renderle disponibili nella prima fase;
7. possibilita di predisporre e inviare preventivi e richieste tramite le
   applicazioni email disponibili sul dispositivo.

La selezione del preventivo o della richiesta deve condurre ai relativi
dettagli senza richiedere percorsi di navigazione complessi. Filtri, elenchi e
dettagli devono essere progettati specificamente per schermi mobili e non come
semplice riproduzione delle pagine desktop.

**Evoluzione successiva [D]**

Le operazioni di inserimento, modifica ed eliminazione sono previste come
possibile evoluzione. La loro predisposizione non ne autorizza
l'implementazione o l'attivazione finche non saranno approvati regole
funzionali, autorizzazioni, validazioni e controlli di concorrenza.

**Vincoli e punti aperti [P]**

- definire un'API HTTPS autenticata tra l'applicazione mobile e il sistema
  Preventivi, evitando l'esposizione diretta di SQL Server su Internet;
- definire autenticazione, ruoli, autorizzazioni, audit, scadenza delle
  sessioni e protezione dei dati memorizzati sul dispositivo;
- scegliere la tecnologia di sviluppo Android e stabilire se prevedere anche
  una futura versione iOS;
- identificare con un elenco approvato le tabelle anagrafiche comprese nella
  prima fase;
- definire filtri, ordinamenti, paginazione e limiti dei risultati per ogni
  area consultabile;
- definire se sia richiesta consultazione offline e, in caso affermativo,
  quali dati possano essere memorizzati localmente e per quanto tempo;
- verificare la generazione o il recupero del documento da allegare all'email;
- utilizzare preferibilmente il selettore di condivisione o composizione email
  di Android, lasciando all'applicazione email scelta dall'utente la selezione
  dell'account mittente. L'eventuale enumerazione diretta degli account del
  dispositivo richiede una verifica tecnica e di riservatezza dedicata.

**Relazioni**

La prima fase non modifica il database e non sostituisce Preventivi.Web. Il
database rimane la fonte dati del sistema; il canale tecnico di accesso remoto
deve essere approvato prima dell'implementazione. Le regole di DA-017 si
applicano alla gestione degli errori, mentre DA-022 e DA-024 costituiscono il
riferimento di coerenza grafica e leggibilita, adattato all'esperienza mobile.

**Riscontri [C] al 21 ottobre 2026**

La registrazione della decisione non attesta l'esistenza dell'applicazione,
di un'API mobile o di servizi esposti da remoto. Non e stata ancora eseguita
una verifica dell'infrastruttura, della sicurezza di rete o dei requisiti di
pubblicazione Android.

## 5. Riscontri e chiarimenti aperti

Questa sezione non aggiunge decisioni approvate.

### 5.1 Razor Partial, ViewComponent e TagHelper

**[C]** La documentazione architetturale descrive la coesistenza di Partial, ViewComponent e TagHelper.

La Decisione 001 indica Razor Partial come componente base, senza dichiararne l’esclusività. La coesistenza non costituisce quindi, da sola, una contraddizione formale.

**[P]** Chiarire i criteri di scelta e l’eventuale consolidamento dei componenti equivalenti.

### 5.2 Lingua dei Model e prefisso CSS

**[C]** Le decisioni storiche prescrivono Model in italiano e prefisso `pfw-`. L’architettura documenta nomi UI inglesi e classi personalizzate `app-*` e `workspace-*`.

Sono scostamenti dell’implementazione; non risultano deroghe approvate nel registro.

**[P]** Chiarire l’ambito delle convenzioni e le eventuali eccezioni per componenti tecnici, codice preesistente e librerie esterne. Non modificare implicitamente il significato delle decisioni storiche.

### 5.3 Application Shell prevista e composizione attuale

**[C]** DA-009 descrive la shell standard prevista. La documentazione architetturale rileva una composizione attuale non integralmente basata sui Partial PFW.

L’attuazione parziale non annulla la decisione.

**[P]** Definire gli interventi di allineamento senza considerare completata la shell prevista.

### 5.4 Parametri e configurazione dello storage

**[C]** L’architettura documenta l’uso di `PercorsoRootAllegati` e la presenza residua di `StorageOptions.ArchivioAllegati`.

La centralizzazione dei parametri gestionali è già decisa. Il consolidamento dei residui tecnici resta distinto.

**[P]** Chiarire il destino della configurazione residua e il confine fra configurazione tecnica di avvio e parametri gestionali. Non introdurre fallback impliciti.

### 5.5 Eliminazione fisica e disattivazione logica

**[D]** DA-016 disciplina specificamente gli allegati.

**[C]** L’architettura descrive comportamenti diversi per altre entità, fra cui disattivazione delle varianti ed eliminazione fisica di elementi della gerarchia.

Non risulta documentata una decisione generale che imponga la disattivazione logica a tutte le entità.

**[P]** Formalizzare separatamente le regole delle altre entità, le cancellazioni collegate e il trattamento degli allegati. Non estendere automaticamente la deroga.

### 5.6 Copertura della gestione errori

**[C]** L’architettura rileva casi prevedibili non ancora tradotti uniformemente nella UI e una pagina diagnostica `TestDb` che espone il messaggio dell’eccezione.

Questi riscontri rappresentano aspetti da verificare rispetto a DA-017, non deroghe approvate.

**[P]** Chiarire trattamento e accessibilità delle pagine diagnostiche e completare la gestione degli errori funzionali.

### 5.7 Completezza degli script SQL

**[C]** `database/README.md` dichiara che la cartella contiene l’intero schema SQL.

**[C]** `docs/01-Architettura.md`, sezione 12.1, documenta invece l’assenza di istruzioni `CREATE TABLE` negli script `.sql` tracciati. La dichiarazione di completezza non è quindi supportata dalla ricognizione documentata.

**[C]** Tutte le 35 procedure richiamate da `PreventivoRepository` risultano definite negli script versionati; molte sono raccolte in `Preventivi_Schede_Workspace.sql`.

La copertura delle procedure non equivaleva alla disponibilità dello schema completo per un’installazione da zero.

**[C]** Al 16 ottobre 2026, TEC-002 ha aggiunto la baseline completa dello
schema installato e ha allineato le istruzioni di installazione. La
completezza inventariale e l'esecuzione della baseline su un database vuoto
sono state verificate con esito positivo.

### 5.8 Riferimenti storici nei documenti

**[C]** `AGENTS.md` indica che `docs/01-Architettura.md` era vuoto alla propria baseline. Il documento è stato successivamente compilato con DOC-02.

È un riferimento storico, non una dichiarazione sullo stato attuale.

**[C]** Analogamente, il documento di architettura descrive il registro precedente a questo consolidamento. Il riferimento alla baseline permette di distinguere lo stato storico dagli aggiornamenti successivi.

**[P]** Mantenere esplicito il riferimento temporale quando si aggiornano questi documenti.

### 5.9 Decisioni funzionali TEC-009

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 16 ottobre 2026.

**Fonte dell’approvazione:** conferme esplicite nella sessione Work dedicata a TEC-009.

Le decisioni approvate per il ricalcolo economico sono:

- **164:** `QuantitaCalcolata` del componente rappresenta il fabbisogno di riferimento;
- **165:** `Quantita` di materiali e lavorazioni rappresenta la quantità operativa totale ed è modificabile;
- **166:** la quantità operativa non viene moltiplicata nuovamente per `QuantitaCalcolata`;
- **167:** eventuali quantità unitarie e totali future devono utilizzare campi distinti, senza reinterpretare il campo storico;
- **168:** creazione ed eliminazione di materiali e lavorazioni ricalcolano atomicamente riga, variante e testata;
- **169:** le righe libere devono essere riconciliate prima del ricalcolo e conservano il costo unitario libero;
- **170:** ogni riga utilizza il proprio `MarkupPerc`; il markup di testata è soltanto il valore predefinito iniziale;
- **171:** la testata comprende le righe comuni e le righe della sola variante attiva selezionata; senza variante selezionata comprende soltanto le righe comuni;
- **172:** una riga libera non può contenere componenti, materiali o lavorazioni;
- **173:** `TotaleCosti` è sempre calcolato: per le righe strutturate deriva da materiali e lavorazioni, per le righe libere da quantità per costo unitario libero;
- **174:** la selezione di una variante sostituisce atomicamente la precedente; è ammessa l’assenza di una variante selezionata.

**Riscontri [C] al 16 ottobre 2026**

Gli script TEC-009 da `01` a `07` e le modifiche applicative collegate sono stati preparati localmente. Gli script dal `02` al `07` risultano applicati e verificati sul database `PreventiviProduzione`; la diagnostica finale non rileva ambiguità bloccanti e conferma l’allineamento dei totali memorizzati.

### 5.10 Decisioni TEC-004 e TEC-011 — Sicurezza e configurazione storage allegati

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 16 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
a TEC-004 e TEC-011.

Le decisioni approvate sono:

- **175:** le sole chiavi di entita consentite per gli allegati sono
  `Clienti`, `Preventivi`, `PreventiviRigheComponenti`,
  `PreventiviRigheMateriali` e `PreventiviRigheLavorazioni`; la whitelist e
  centralizzata e il confronto e esatto;
- **176:** la root dello storage deve essere un percorso assoluto; ogni
  percorso canonico costruito deve rimanere al suo interno;
- **177:** percorsi relativi e nomi dei file archiviati non possono essere
  assoluti, contenere `..` o segmenti di directory impropri;
- **178:** salvataggio, apertura ed eliminazione rifiutano i percorsi non
  validi prima di qualsiasi operazione sul filesystem, senza fallback;
- **179:** root mancante o non valida e metadati di percorso non validi
  producono errori dedicati e prevedibili; l'errore tecnico viene registrato,
  mentre l'interfaccia non espone percorsi fisici;
- **180:** la validazione e applicata sia all'ingresso Web sia nello storage
  come difesa in profondita. La verifica dell'esistenza e dell'autorizzazione
  di `IdEntita` resta nell'ambito di TEC-005;
- **181:** viene introdotto il primo progetto di test automatici, limitato in
  questa fase alla sicurezza dei percorsi dello storage allegati.

**Riscontri [C] al 16 ottobre 2026**

L'implementazione e i test relativi a queste decisioni sono presenti
localmente. La suite mirata dello storage allegati ha superato 14 test su 14;
non sono state apportate modifiche al database.

### 5.11 Decisioni TEC-005 — Autenticazione e autorizzazione

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 16 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
a TEC-005.

Le decisioni approvate sono:

- **182:** utilizzare `UtentiApplicazione`, `RuoliApplicazione` e
  `UtentiRuoli` come fonte dell'identita, senza aggiungere lo schema ASP.NET
  Identity;
- **183:** memorizzare le password esclusivamente tramite il password hasher
  ASP.NET Core e mai in testo in chiaro;
- **184:** utilizzare autenticazione cookie e negare per impostazione
  predefinita l'accesso anonimo, salvo Login ed Error;
- **185:** caricare soltanto ruoli attivi di utenti attivi; il ruolo `ADMIN`
  dispone dell'accesso applicativo completo;
- **186:** mantenere una mappatura esplicita fra i nomi storici Access e i
  moduli Web; un permesso assente nega l'accesso, salvo `ADMIN`;
- **187:** applicare l'autorizzazione ai PageModel e agli handler, comprese le
  operazioni dirette sugli allegati, senza affidarsi al solo menu;
- **188:** utilizzare un cookie non persistente, con scadenza mobile di dodici
  ore e chiusura alla chiusura del browser;
- **189:** rendere `Dev` e `TestDb` accessibili soltanto in Development e al
  ruolo `ADMIN`, senza mostrare errori tecnici nella UI;
- **190:** inizializzare la prima password amministrativa tramite comando
  locale interattivo, senza segreti nei file o nella cronologia dei comandi;
- **191:** rimuovere le credenziali SQL dal repository, ruotare la credenziale
  esposta e utilizzare configurazione esterna con un account applicativo a
  privilegi minimi;
- **192:** verificare automaticamente password, cookie, ruoli, permessi e
  protezione delle operazioni.

**Riscontri [C] al 16 ottobre 2026**

L'implementazione applicativa e presente localmente. Sono stati aggiunti
login, logout, cookie di sessione, policy per modulo, protezione degli
allegati, restrizioni per le pagine diagnostiche e comando di inizializzazione
della password amministrativa. La connessione di sviluppo e stata trasferita
nel Secret Store locale e il file versionato non contiene piu la credenziale.

I 16 test automatici della sicurezza Web e i 14 test dello storage allegati
sono terminati senza errori. Nel browser e stata verificata la pagina Login e
il reindirizzamento anonimo dalla dashboard.

Le due procedure TEC-005 e lo script per l'account SQL a privilegi minimi sono
soltanto preparati nel repository: non sono stati applicati al database. La
password amministrativa non e stata inizializzata, l'account SQL dedicato non
e stato creato e la precedente credenziale SQL non e stata ruotata.

### 5.12 Decisioni TEC-006 — Compensazione fra storage e database

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 19 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
a TEC-006.

Le decisioni approvate sono:

- **193:** creazione e cancellazione degli allegati sono coordinate
  dall'Application Service;
- **194:** la creazione del file temporaneo e compresa nel blocco di pulizia;
- **195:** se l'inserimento SQL fallisce, il file gia archiviato viene
  eliminato come compensazione;
- **196:** durante l'eliminazione il file viene prima spostato in una cartella
  di quarantena interna alla root, quindi il record SQL viene eliminato e il
  file viene cancellato definitivamente;
- **197:** se l'eliminazione SQL fallisce, il file viene ripristinato dalla
  quarantena;
- **198:** i fallimenti delle compensazioni sono registrati come critici senza
  esporre percorsi fisici nell'interfaccia;
- **199:** i passaggi intermedi e i relativi errori sono verificati mediante
  test automatici con fallimenti simulati.

**Riscontri [C] al 19 ottobre 2026**

L'Application Service coordina upload, repository e quarantena. Lo storage
rimuove i file parziali in caso di copia non completata; dopo la prima modifica
al filesystem, completamento e compensazioni non dipendono piu
dall'annullamento della richiesta HTTP. La UI mantiene messaggi funzionali e
non espone i percorsi dello storage.

La suite completa ha superato 23 test Data e 18 test Web. Non sono state
necessarie modifiche al database. TEC-007 resta distinta e disciplina le
future cancellazioni degli allegati collegate alla gerarchia del preventivo.

### 5.13 Decisioni TEC-007 — Cancellazioni della gerarchia e allegati

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 20 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
a TEC-007.

Le decisioni approvate sono:

- **200:** eliminare fisicamente gli allegati quando viene eliminata
  fisicamente l'entita proprietaria;
- **201:** eliminando un materiale o una lavorazione vengono eliminati i
  rispettivi allegati;
- **202:** eliminando un componente foglia vengono eliminati i suoi allegati
  e quelli dei suoi materiali e lavorazioni;
- **203:** un componente con figli non viene eliminato; l'utente deve prima
  rimuovere i figli, mantenendo la protezione attuale;
- **204:** eliminando una riga vengono eliminati gli allegati di tutti i
  componenti, materiali e lavorazioni contenuti;
- **205:** la disattivazione di una variante conserva righe e allegati;
- **206:** i file interessati vengono spostati insieme in quarantena; una
  sola transazione SQL elimina record `Allegati`, entita e ricalcola i
  totali;
- **207:** se la transazione SQL fallisce, tutti i file vengono ripristinati;
  se anche un solo file non puo essere messo in quarantena, l'operazione
  viene annullata prima di modificare il database;
- **208:** un file gia mancante non blocca la pulizia del relativo record SQL
  e l'anomalia viene registrata; un fallimento della pulizia finale della
  quarantena viene registrato come critico;
- **209:** la transazione verifica che l'elenco degli allegati non sia
  cambiato nel frattempo e, in caso di modifica concorrente, annulla la
  cancellazione;
- **210:** il comportamento viene coperto da test automatici per successo,
  rollback, file mancante, errore storage e modifica concorrente.

**Riscontri [C] al 21 ottobre 2026**

TEC-006 fornisce la quarantena e la compensazione per il singolo allegato.
Nel repository sono stati predisposti il coordinamento applicativo dei gruppi
di file, le eliminazioni di riga, componente, materiale e lavorazione, il
controllo concorrente dell'elenco allegati e lo script SQL transazionale
`TEC-007_01_Eliminazioni_Gerarchia_Allegati.sql`.

La compilazione della soluzione e completata con zero errori; risultano
superati 28 test Data e 26 test Web, inclusi i casi TEC-007 di successo,
rollback SQL, file mancante, errore storage e modifica concorrente.

Il 20 ottobre 2026 l'utente ha confermato l'applicazione senza errori dello
script al database di test e l'esito positivo delle prove runtime relative a:
eliminazione di materiale con allegato, lavorazione con allegato, componente
foglia con contenuti e allegati, rifiuto dell'eliminazione di un componente
con figli ed eliminazione completa di una riga strutturata con aggiornamento
dei totali. Le prove runtime attestano il percorso funzionale ordinario; i
casi di errore e concorrenza restano coperti dai test automatici e non da
simulazioni manuali sul database.

### 5.14 Decisioni TEC-008 — Creazione del preventivo

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 20 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
alla prosecuzione della gestione Preventivi.

Le decisioni approvate sono:

- **211:** la creazione del preventivo supporta le origini Libero, Richiesta
  cliente e Modello preventivo;
- **212:** il numero e progressivo per anno ed e assegnato automaticamente in
  modo concorrente e transazionale;
- **213:** la data viene proposta con il giorno corrente ed e modificabile;
- **214:** lo stato iniziale e sempre `Bozza`;
- **215:** il cliente e obbligatorio per l'origine Libero; per Richiesta e
  Modello viene proposto dai dati di origine;
- **216:** la maschera iniziale comprende cliente, oggetto, note e markup
  predefinito, oltre a data e origine;
- **217:** dopo il salvataggio viene aperto il dettaglio del nuovo preventivo;
- **218:** le modifiche al database sono distribuite mediante script SQL
  versionato e applicate prima della prova runtime;
- **219:** l'eliminazione dell'intero preventivo resta un intervento separato,
  da definire rispetto a richieste, varianti, righe e allegati.
- **220:** nella creazione da Richiesta cliente il cliente viene ereditato
  dalla richiesta e non e sostituibile; se e assente o non attivo, la
  creazione viene bloccata con un messaggio esplicito.
- **221:** nella creazione da Modello preventivo, cliente, oggetto e note del
  modello sono valori iniziali modificabili prima del salvataggio;
- **222:** dal modello vengono copiate esclusivamente le righe presenti in
  `ModelliPreventivoRighe`; componenti, materiali e lavorazioni non vengono
  copiati dal modello attuale;
- **223:** il preventivo creato conserva il collegamento al modello di origine,
  ma le successive modifiche del modello non aggiornano il preventivo gia
  creato;
- **224:** nella creazione sono selezionabili soltanto modelli attivi e
  l'eventuale cliente associato al preventivo deve risultare attivo al momento
  del salvataggio;
- **225:** la gestione completa dei modelli preventivo costituisce un
  intervento separato. Il collaudo conclusivo di TEC-008 deve utilizzare un
  modello reale proveniente dal flusso di gestione o importazione oppure uno
  script di prova controllato.
- **226:** ogni riga di un modello preventivo deve memorizzare esplicitamente
  il proprio `IdTipoRiga`;
- **227:** `ModelliPreventivoRighe.IdTipoRiga` deve essere protetto da una
  chiave esterna verso `TipiRigaPreventivo.IdTipoRiga`;
- **228:** la migrazione delle righe modello esistenti puo assegnare
  automaticamente il tipo soltanto quando questo e determinabile senza
  ambiguita. In presenza di piu tipi compatibili, lo script deve interrompersi
  e segnalare le righe da classificare;
- **229:** la creazione da modello deve copiare e validare il tipo registrato
  nella riga modello, senza selezionare automaticamente il primo tipo riga
  compatibile.

**Riscontri [C] al 20 ottobre 2026**

Nel repository sono stati predisposti la pagina di creazione, i lookup di
clienti, richieste e modelli, il collegamento dall'elenco e lo script
transazionale `TEC-008_01_Creazione_Preventivo.sql`. La compilazione della
soluzione e completata con zero errori e le suite di regressione hanno
superato 28 test Data e 26 test Web.

Il 20 ottobre 2026 l'utente ha confermato l'applicazione dello script al
database di test senza errori. La prova runtime ha verificato l'apertura della
pagina, le origini Libero, Richiesta cliente e Modello preventivo, i relativi
lookup e la creazione libera del preventivo `2026-00002`: stato iniziale
Bozza, data corrente, cliente TECNOCED, markup predefinito 60%, totali iniziali
a zero e reindirizzamento al dettaglio. La creazione da modello preventivo non
risulta ancora collaudata con salvataggio effettivo; nel database di test non
erano disponibili modelli selezionabili.

Nella stessa data l'utente ha approvato la decisione 220 e ha confermato
l'applicazione senza errori dello script incrementale
`TEC-008_02_Vincolo_Cliente_Richiesta.sql`. Il collaudo browser sulla richiesta
`2026-00001` ha verificato il caso negativo: il cliente inattivo `TEST` viene
mostrato in sola lettura, l'oggetto viene proposto, compare il messaggio
esplicito e l'azione Salva risulta disabilitata.

Il 21 ottobre 2026 il controllo applicativo e stato allineato all'elenco dei
clienti attivi caricato dalla stessa connessione. Il collaudo positivo ha
creato il preventivo `2026-00003` dalla richiesta `2026-00001`, con stato
iniziale Bozza, cliente `Cliente Test S.r.l.`, oggetto e markup proposti,
collegamento alla richiesta e reindirizzamento al dettaglio. La richiesta e
stata aggiornata allo stato `Preventivata`. Il rifiuto runtime della stored
procedure contro dati alterati non risulta collaudato mediante una chiamata
diretta.

Nella stessa data l'utente ha approvato le decisioni 221-225 relative alla
creazione da Modello preventivo. La loro registrazione non costituisce prova
del flusso runtime: il salvataggio da modello resta da collaudare con un
modello attivo e con righe reali o predisposte mediante uno script controllato.

La ricognizione successiva ha rilevato che `ModelliPreventivoRighe` non
memorizza attualmente `IdTipoRiga` e che la procedura TEC-008 sceglie il primo
tipo attivo compatibile in base alla sola presenza dell'articolo. Il 21 ottobre
2026 l'utente ha quindi approvato le decisioni 226-229.

Nel repository e stato predisposto lo script
`TEC-008_03_Tipo_Riga_Modelli.sql`: aggiunge la colonna, migra solo le righe
classificabili senza ambiguita, applica `NOT NULL` e chiave esterna e sostituisce
il fallback `TOP (1)` con la copia del tipo registrato. Il 21 ottobre 2026
l'utente ha confermato l'esecuzione dello script sul database senza errori. Il
flusso da modello non e ancora collaudato a runtime.

La successiva ricognizione dei tipi riga reali ha verificato che soltanto
`ART` ha `RigaArticolo = 1`, mentre `MostraArticolo = 1` e presente anche sui
tipi liberi. Sono stati quindi predisposti gli script incrementali
`MB-02_05_Regole_Riga_Articolo.sql` e
`TEC-008_04_Regole_Riga_Articolo_Modelli.sql`, che usano `RigaArticolo` come
discriminante senza modificare la configurazione esistente. Per il collaudo,
in assenza di modelli reali, e stato inoltre predisposto
`TEC-008_05_Modello_Collaudo_Articolo.sql`, basato sul tipo `ART` e
sull'articolo attivo `GAB.01.001` indicati dall'utente. Il 23 ottobre 2026
l'utente ha confermato l'esecuzione senza errori di tutti e tre gli script; il
successivo collaudo runtime e stato superato. Sono stati verificati il
passaggio tra riga Articolo e Materiale libero, la compilazione o lo
svuotamento della descrizione, l'obbligatorieta coerente del costo libero e la
creazione del preventivo dal modello controllato `TEST-TEC008-ART` con tipo
`ART` e articolo `GAB.01.001`.

### 5.15 Decisioni TEC-010 — Gestione modelli preventivo

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 23 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work dedicata
alla prosecuzione successiva a TEC-008.

Le decisioni approvate sono:

- **230:** creare il modulo Web `Modelli preventivo`, protetto dal permesso
  applicativo dei Preventivi;
- **231:** l'elenco espone ricerca e filtri per codice, descrizione, cliente e
  stato;
- **232:** la testata gestisce codice univoco, descrizione obbligatoria,
  cliente facoltativo, oggetto, note e stato;
- **233:** le righe dispongono delle azioni `Nuovo`, `Modifica` ed `Elimina` e
  applicano le regole dinamiche gia approvate per le righe preventivo;
- **234:** l'eliminazione di un modello e logica mediante disattivazione, in
  modo da conservare la tracciabilita dei preventivi che lo hanno utilizzato;
- **235:** un modello disattivato puo essere riattivato;
- **236:** una singola riga modello puo essere eliminata fisicamente previa
  conferma, poiche i preventivi gia creati ne conservano una copia autonoma;
- **237:** il modulo deve essere raggiungibile mediante collegamenti reali dal
  menu e dalla dashboard;
- **238:** componenti, materiali e lavorazioni non fanno parte di TEC-010: il
  modello corrente contiene e trasferisce esclusivamente le righe definite in
  `ModelliPreventivoRighe`.

**Riscontri [C] al 23 ottobre 2026**

Prima dell'implementazione risultano presenti le tabelle
`ModelliPreventivo` e `ModelliPreventivoRighe`, i relativi vincoli nella
baseline TEC-002, il tipo riga esplicito introdotto da TEC-008 e il solo lookup
dei modelli attivi usato nella creazione del preventivo. Non risultano pagine
Web o operazioni repository dedicate alla gestione completa dei modelli.

Nel repository sono ora predisposti il contratto e il repository dedicati, le
pagine di elenco, creazione, modifica, disattivazione e riattivazione, la
gestione completa delle righe, i collegamenti da menu e dashboard e lo script
`TEC-010_01_Gestione_Modelli_Preventivo.sql`. Lo script ha superato il
controllo sintattico ScriptDom.

Il 23 ottobre 2026 lo script e stato applicato a `PreventiviProduzione` dopo
una diagnostica senza riferimenti orfani. La verifica successiva ha confermato
10 procedure TEC-010 installate e i 5 vincoli richiesti attivi e affidabili.
La soluzione compila con zero errori; hanno superato la verifica 28 test Data
e 30 test Web, inclusi quattro test di validazione dei form TEC-010.

Il collaudo runtime ha verificato elenco e ricerca, creazione e modifica della
testata, compilazione del cliente e dei valori proposti, inserimento di una
riga Articolo con descrizione automatica e modello ciclo, inserimento e
modifica di una riga Materiale libero e la relativa conferma di eliminazione.
L'eliminazione della riga di prova e la disattivazione e riattivazione del
modello sono state verificate direttamente mediante le procedure TEC-010.
La creazione da modello e stata infine eseguita in una transazione di collaudo:
testata, collegamento al modello, cliente, stato Bozza e riga Articolo sono
risultati corretti; il rollback finale ha confermato l'assenza di preventivi
residui. TEC-010 risulta quindi chiusa per l'ambito approvato dalle decisioni
230-238.

### 5.16 Decisioni TEC-012 — Versionamento database

**Classificazione:** [D].

**Stato:** approvate.

**Data di approvazione:** 26 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita nella sessione Work.

Le decisioni approvate sono:

- **239:** introdurre l'intervento TEC-012 per il versionamento esplicito dello
  schema database;
- **240:** usare il registro append-only `dbo.VersioniSchema`, nel quale ogni
  aggiornamento applicato conserva versione, codice intervento, script,
  descrizione, data, operatore e impronta SHA-256;
- **241:** usare una versione numerica nel formato `AAAAMMGGNN`, con baseline
  iniziale `2026102601`;
- **242:** lo script iniziale registra la baseline soltanto dopo aver verificato
  la presenza degli oggetti applicativi richiesti fino a TEC-010;
- **243:** ogni futuro aggiornamento database deve essere transazionale,
  incrementare la versione e registrare codice, script, descrizione, data,
  operatore e impronta SHA-256;
- **244:** l'applicazione verifica la versione in sola lettura e non esegue
  automaticamente script o migrazioni;
- **245:** database non disponibile, registro assente o versione diversa da
  quella supportata bloccano le funzioni operative e mostrano una pagina di
  manutenzione leggibile, conservando il dettaglio tecnico nei log.

**Riscontri [C] al 26 ottobre 2026**

Nel repository sono predisposti lo script incrementale
`TEC-012_01_Versionamento_Database.sql`, il contratto e il verificatore della
versione, il controllo di avvio, il middleware di blocco e la pagina di
manutenzione. Lo script verifica gli oggetti rappresentativi richiesti fino a
TEC-010, crea il registro append-only e la procedura di lettura della versione
corrente, quindi registra la baseline `2026102601` con la relativa impronta.

Lo script ha superato il controllo sintattico ScriptDom e la verifica
dell'impronta SHA-256 dichiarata. La soluzione compila con zero errori; sono
stati superati 28 test Data e 36 test Web. Prima dell'applicazione dello script,
il collaudo runtime ha confermato il riconoscimento dello stato
`NonInizializzato`, il redirect da `/Preventivi` a `/Sistema/Database` e la
pagina di manutenzione HTTP 200 con versione richiesta `2026102601` e versione
installata non rilevata.

Il 26 ottobre 2026 lo script e stato applicato senza errori al database di
test. La verifica successiva ha confermato la baseline `2026102601`, il codice
`TEC-012-BASELINE`, il nome e l'impronta dello script, la procedura
`dbo.Sistema_VersioneSchema_Corrente` e il trigger append-only attivo come
`INSTEAD OF UPDATE, DELETE`.

Il collaudo applicativo post-installazione ha avviato Preventivi.Web senza
segnalazioni di incompatibilita. La richiesta a `/Preventivi` e tornata al
normale flusso di autenticazione, con redirect a `/Account/Login`, invece della
pagina di manutenzione. TEC-012 risulta quindi chiusa per l'ambito approvato
dalle decisioni 239-245.

### 5.17 Decisioni TEC-013 — Gestione Richieste Clienti

**Classificazione:** [D].

**Stato:** approvate, installate e collaudate.

**Data di approvazione:** 26 ottobre 2026.

**Fonte dell'approvazione:** conferme esplicite, in quattro pacchetti da cinque
decisioni, nella sessione Work.

Le decisioni approvate sono:

- **246:** sostituire la pagina dimostrativa con le pagine operative `Elenco`,
  `Nuova`, `Dettaglio` e `Modifica`;
- **247:** usare dati reali e filtri combinabili per testo libero, cliente,
  stato, priorita, interesse e intervallo di scadenza;
- **248:** assegnare il numero progressivo annuale nella stessa transazione
  SQL dell'inserimento, con protezione dalla concorrenza;
- **249:** richiedere un cliente attivo alla creazione e per ogni cambio di
  cliente, conservando la leggibilita del cliente corrente se disattivato;
- **250:** valorizzare `DataAttivazione` al primo avanzamento e
  `DataChiusura` per gli stati finali `Confermata`, `Persa` e `Annullata`, che
  non possono essere riaperti senza una nuova decisione;
- **251:** non eliminare fisicamente le richieste; l'azione approvata e
  `Annulla richiesta`, con conferma e conservazione di collegamenti, allegati
  e storico;
- **252:** mostrare nel dettaglio tutti i campi e i preventivi e le
  campionature collegati, usando collegamenti solo verso pagine operative;
- **253:** consentire dal dettaglio la creazione di piu preventivi con
  richiesta, cliente e oggetto preselezionati;
- **254:** estendere MB-01 con la chiave allegato `RichiesteClienti` e le
  operazioni esistenti di inserimento, apertura, download ed eliminazione;
- **255:** usare `rowversion` per modifica e annullamento, mostrando un
  messaggio leggibile in caso di conflitto concorrente;
- **256:** alimentare la dashboard con conteggi e alert reali per richieste
  urgenti, scadute o in scadenza;
- **257:** proteggere pagine e operazioni con il permesso applicativo
  `frmRichiesteClientiElenco`, verificato sul server;
- **258:** distribuire TEC-013 mediante uno script transazionale che porta il
  database da `2026102601` a `2026102602` e registra l'intervento in
  `dbo.VersioniSchema`;
- **259:** coprire validazione, servizi, concorrenza, annullamento,
  autorizzazioni e collegamenti con test automatici e completare un collaudo
  runtime comprensivo di richiesta e preventivo collegato;
- **260:** applicare PFW e DA-022/DA-024; data, cliente, oggetto, stato e
  priorita sono obbligatori, mentre probabilita 0-100, descrizione, interesse,
  scadenza e note sono facoltativi; le date operative non sono modificabili
  manualmente;
- **261:** mantenere il flusso UI -> Application Service -> Repository ->
  Database tramite `IRichiestaClienteApplicationService`;
- **262:** rendere il cliente immutabile dopo il collegamento del primo
  preventivo o della prima campionatura;
- **263:** consentire la creazione di preventivi soltanto negli stati `Nuova`,
  `In Valutazione`, `Da Preventivare` e `Preventivata`; una richiesta sospesa
  deve essere prima riattivata e gli stati finali non ammettono nuove
  operazioni;
- **264:** rendere stampabili elenco filtrato e dettaglio, nascondendo i
  controlli operativi in stampa;
- **265:** registrare utente di creazione, utente di ultima modifica,
  `DataCreazione` e `DataModifica`; cambi stato, annullamento e creazione del
  preventivo aggiornano l'audit con l'utente autenticato.

Estensione approvata il 27 ottobre 2026:

- **266:** conservare nel database la richiesta annullata con numero,
  allegati e documenti collegati;
- **267:** escludere le richieste annullate dalle attivita operative e dagli
  alert ordinari;
- **268:** aggiungere nel dettaglio il comando dedicato `Riattiva richiesta`,
  separato dalla normale modifica e protetto da conferma esplicita;
- **269:** riportare la richiesta riattivata allo stato `Nuova`, rimuovere la
  data di chiusura, conservare la prima attivazione e registrare utente e data
  dell'operazione applicando il controllo `rowversion`;
- **270:** non esporre eliminazioni fisiche nella gestione ordinaria; una
  futura pulizia definitiva richiedera una funzione amministrativa separata e
  una decisione esplicita.

**Riscontri [C] al 26 ottobre 2026**

Nel repository sono predisposti i contratti Core, l'Application Service, il
repository ADO.NET, le pagine Razor operative, i filtri, l'annullamento, i
collegamenti, gli allegati, la dashboard, la stampa e lo script incrementale
`TEC-013_01_Gestione_Richieste_Clienti.sql`. Lo script attende la baseline
`2026102601`, aggiunge audit e `rowversion`, crea nove procedure e registra la
versione `2026102602` con impronta SHA-256.

La soluzione compila con zero errori. Il controllo ScriptDom ha validato lo
script esterno e tutte le nove definizioni dinamiche; risultano superati 32
test Data e 41 test Web. Persistono gli avvisi NuGet noti relativi a
`System.Security.Cryptography.Pkcs` 9.0.13.

Lo script `TEC-013_01` risulta installato nel database con versione
`2026102602` e impronta verificata. Sono stati collaudati a runtime apertura
dell'elenco, creazione, modifica, annullamento logico, filtri combinati e
allegati. Il collegamento completo richiesta-preventivo resta da collaudare.

Per le decisioni 266-270 sono stati installati e collaudati il comando
applicativo, la pagina Razor di conferma e lo script incrementale
`TEC-013_02_Riattivazione_Richieste_Clienti.sql`, che porta lo schema a
`2026102701`. Il collaudo runtime ha confermato anche la trasformazione della
richiesta in preventivo.

### 5.18 Decisioni TEC-014 — Gestione base Campionature

**Classificazione:** [D].

**Stato:** approvate; implementazione predisposta, script non ancora applicato
al database.

**Data di approvazione:** 27 ottobre 2026.

**Fonte dell'approvazione:** conferma esplicita delle decisioni 271-275 nella
sessione Work.

Le decisioni approvate sono:

- **271:** sostituire la pagina dimostrativa Campionature con le pagine
  operative `Elenco`, `Nuova`, `Dettaglio` e `Modifica`, alimentate dai dati
  reali;
- **272:** rendere obbligatorio per ogni campionatura il collegamento a una
  richiesta cliente;
- **273:** mantenere facoltativi preventivo e variante, verificando che il
  preventivo appartenga alla richiesta e la variante al preventivo;
- **274:** consentire la creazione sia dall'elenco Campionature sia dal
  dettaglio Richiesta Cliente, con preselezione di richiesta, cliente, oggetto
  e priorita;
- **275:** non riutilizzare direttamente la procedura legacy
  `sp_CreaCampionaturaDaRichiesta`; distribuire procedure versionate e
  transazionali con numerazione annuale concorrente, validazione, audit e
  controllo `rowversion`.

**Riscontri [C] al 27 ottobre 2026**

Nel repository sono predisposti contratti Core, Application Service,
repository ADO.NET, pagine Razor, collegamenti da sidebar, dashboard e
richiesta cliente e lo script incrementale
`TEC-014_01_Gestione_Campionature.sql`. Lo script richiede `2026102701` e
registra `2026102702` con codice `TEC-014-BASE`. Rilievi, adeguamenti,
allegati e azioni dedicate di chiusura o annullamento restano fuori da questo
pacchetto e richiedono decisioni successive.

La soluzione compila con zero errori. Sono stati superati 37 test Data e 44
test Web. ScriptDom ha validato lo script esterno e tutti i 13 batch dinamici;
l'impronta SHA-256 dichiarata e stata ricalcolata e verificata. Persistono gli
avvisi NuGet noti relativi a `System.Security.Cryptography.Pkcs` 9.0.13. Lo
script non e stato eseguito sul database e il flusso non e ancora collaudato a
runtime.

## 6. Implementazioni e proposte non promosse a decisioni

### 6.1 Implementazioni documentate [C]

Restano descrizioni dell’implementazione:

- versione .NET e dipendenze correnti dei quattro progetti;
- collocazione attuale dei servizi e dei contratti;
- accesso diretto ai repository da diversi PageModel;
- organizzazione fisica dello storage;
- associazione degli allegati mediante `Entita` e `IdEntita`;
- gerarchia operativa dei preventivi;
- associazione di materiali e lavorazioni mediante riga e nodo distinta;
- formule presenti nelle stored procedure;
- comportamenti correnti di eliminazione e disattivazione;
- stato dei moduli e presenza di pagine dimostrative;
- assenza di progetti di test automatizzati nella baseline documentata.

La loro presenza nella documentazione non ne costituisce approvazione funzionale generale.

### 6.2 Proposte ancora da valutare [P]

Restano proposte, fra le altre:

- estensione dei servizi applicativi a tutti i flussi;
- revisione della collocazione dei contratti;
- consolidamento di Partial, ViewComponent e TagHelper;
- associazione univoca dei materiali e delle lavorazioni al componente;
- regole complete di ricalcolo e propagazione dei totali;
- comportamento delle varianti;
- gestione dei fallimenti fra filesystem e SQL Server;
- conversione tipizzata dei parametri;
- strategia di test e verifica;
- regole operative contrassegnate `[P]` in `AGENTS.md`.

L’approvazione della pubblicazione di un documento non promuove automaticamente queste proposte a decisioni `[D]`.

## 7. Struttura proposta per le future aggiunte

**[P]** Utilizzare identificativi stabili e progressivi, senza rinumerare le decisioni esistenti e senza riutilizzare identificativi storici.

**[P]** Per ogni nuova voce utilizzare questa struttura:

```
### DA-NNN — Titolo

**Classificazione:** [D] oppure [P].
**Stato:** approvata / proposta / superata.
**Data di approvazione:** indicare solo se nota; altrimenti
“non documentata” o “non applicabile”.
**Fonte dell’approvazione:** riferimento verificabile, se disponibile.

**Contesto**

Problema o esigenza che motiva la voce.

**Decisione [D] oppure proposta [P]**

Testo preciso, con ambito ed eventuali eccezioni.

**Relazioni**

Decisioni collegate ed eventuale decisione sostituita.

**Riscontri [C]**

Stato dell’implementazione, fonte e riferimento temporale.
Non dichiarare implementata una decisione soltanto perché approvata.

**Punti aperti [P]**

Questioni non ancora approvate o attività da valutare.
```

**[P]** Quando una decisione viene sostituita, conservarne il contenuto storico e collegarla alla nuova decisione, evitando cancellazioni o riscritture retroattive del significato.

**[P]** Prima di aggiungere una voce, verificare se il contenuto è già coperto da una decisione esistente. Utilizzare rimandi per i contenuti coincidenti e nuove voci soltanto per disposizioni distinte.

**[D]** La registrazione delle nuove approvazioni e la distinzione fra decisioni, implementazioni e proposte restano disciplinate da DA-020.

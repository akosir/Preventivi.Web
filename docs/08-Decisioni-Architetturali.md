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
   tramite i componenti UI del progetto.

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

**Riscontri [C] al 20 ottobre 2026**

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
a zero e reindirizzamento al dettaglio. La creazione da richiesta cliente e da
modello preventivo non risulta ancora collaudata con salvataggio effettivo; nel
database di test non erano disponibili modelli selezionabili.

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

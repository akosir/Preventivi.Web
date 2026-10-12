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

La copertura delle procedure non equivale alla disponibilità dello schema completo per un’installazione da zero.

**[P]** Allineare la documentazione di installazione e completare la rappresentazione dello schema, mantenendo DA-014 come regola di riferimento.

### 5.8 Riferimenti storici nei documenti

**[C]** `AGENTS.md` indica che `docs/01-Architettura.md` era vuoto alla propria baseline. Il documento è stato successivamente compilato con DOC-02.

È un riferimento storico, non una dichiarazione sullo stato attuale.

**[C]** Analogamente, il documento di architettura descrive il registro precedente a questo consolidamento. Il riferimento alla baseline permette di distinguere lo stato storico dagli aggiornamenti successivi.

**[P]** Mantenere esplicito il riferimento temporale quando si aggiornano questi documenti.

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
- coordinamento delle cancellazioni e degli allegati;
- gestione dei fallimenti fra filesystem e SQL Server;
- conversione tipizzata dei parametri;
- strategia di autenticazione e autorizzazione;
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

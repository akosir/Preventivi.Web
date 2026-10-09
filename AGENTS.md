# AGENTS.md — Preventivi.Web

## 1. Ambito e attendibilità delle informazioni

Queste istruzioni si applicano al repository Preventivi.Web.

Baseline della proposta:
- branch: feature/workspace-preventivo;
- commit: 646aa81bc6993362a56fdc423c3d68a805d57b00;
- descrizione: MB-02 consolidamento Work: componenti, materiali,
  lavorazioni e dashboard.

Le indicazioni sono distinte in:
- [D] decisioni o regole presenti nella documentazione;
- [C] struttura o comportamento verificato nel codice della baseline;
- [P] regole operative proposte con questo file.

Le indicazioni [C] non attestano un'approvazione funzionale.
Le indicazioni [P] non devono essere presentate come decisioni
storicamente già approvate.

[D] Le integrazioni contrassegnate [D] relative a parametri gestionali,
eliminazione allegati, gestione errori, prosecuzione sulla versione Web,
consultazione delle fonti e registrazione delle decisioni sono decisioni
esplicitamente approvate dall'utente durante la creazione di questo file.
La categoria [D] comprende anche queste decisioni approvate.

Fonti:
- README.md;
- docs/08-Decisioni-Architetturali.md;
- docs/03-Workspace.md;
- database/README.md;
- codice e script SQL versionati.

Alla baseline:
- docs/PFW-DesignBook.md e docs/01-Architettura.md sono vuoti;
- docs/08-Decisioni-log.md non esiste;
- diversi documenti tecnici e funzionali sono ancora vuoti.

[P] Non ricavare requisiti da titoli, file vuoti, cartelle predisposte
o schermate incomplete.

[P] In caso di conflitto fra documentazione, codice e richiesta,
esplicitare la differenza prima di introdurre cambiamenti funzionali.
Non considerare automaticamente il codice come approvazione di una
decisione mancante.

[D] Prima di modifiche architetturali o funzionali, consultare AGENTS.md,
il registro decisioni del repository e la documentazione consolidata.
Non presumere accesso automatico alle chat ChatGPT o Work.

## 2. Architettura e dipendenze

[D] Tecnologie:
- ASP.NET Core;
- Razor Pages;
- SQL Server;
- ADO.NET;
- Bootstrap.

[C] I quattro progetti applicativi utilizzano .NET 10, nullable
reference types e implicit usings.

[C] Organizzazione:
- src/Preventivi.Core: modelli di dominio, contratti repository,
  contratti applicativi e DTO dello storage;
- src/Preventivi.Data: accesso SQL, repository, mapping,
  implementazioni dei servizi allegati e parametri;
- src/Preventivi.Shared: progetto condiviso, attualmente con
  cartelle predisposte per funzionalità comuni;
- src/Preventivi.Web: Razor Pages, PageModel, UI, layout,
  componenti e registrazione dei servizi.

[C] Dipendenze:
- Web -> Core, Data, Shared;
- Data -> Core, Shared;
- Core -> Shared.

[P] Conservare questa direzione delle dipendenze.
Non introdurre dipendenze da Core verso Web o Data.

[C] Program.cs è il punto di composizione dei servizi.
La connessione SQL è individuata dalla chiave PreventiviDb.

[P] Riutilizzare i servizi registrati tramite dependency injection.
Non introdurre connessioni SQL nei file Razor.

[P] Non introdurre ORM, nuovi framework UI o riorganizzazioni
strutturali come conseguenza implicita di una modifica locale.

[D] Proseguire esclusivamente sulla versione Web.
Non riprendere il frontend Access senza richiesta esplicita.

## 3. Organizzazione dei moduli e dei componenti

[C] Il codice di dominio e persistenza è organizzato per area:
Preventivi, Clienti, Allegati e ParametriSistema.

[C] Organizzazione Web:
- Pages/<Modulo>: pagine e PageModel;
- Pages/Shared/<Modulo>: Partial specifici del modulo;
- Pages/Shared/PFW: Partial riutilizzabili del framework;
- UI/Modules/<Modulo>: modelli UI specifici;
- UI/<Componente>: modelli UI del framework;
- Mappers/<Modulo>: mapping di presentazione;
- wwwroot/css/framework: stili PFW.

[C] Esistono anche ViewComponent in Components,
relative viste in Pages/Shared/Components e TagHelper.

[P] Per una modifica locale, seguire il modello già adottato
dalla funzionalità interessata ed evitare ulteriori duplicazioni.
Una convergenza fra Partial, ViewComponent e TagHelper richiede
un intervento esplicito.

[D] Il framework PFW non contiene logica di dominio.

[P] Non inserire regole di preventivazione nei componenti grafici
generici.

[P] La presenza di cartelle o pagine relative a Richieste,
Campionature, Ordini o altre aree non dimostra che il modulo sia
completo o che il suo comportamento sia stato approvato.

## 4. Decisioni documentate del framework

[D] Decisione 001:
Razor Partial è il componente base del PFW.

[D] Decisione 002:
i Model sono in italiano.

[D] Decisione 003:
le classi CSS utilizzano il prefisso pfw-.

[D] Decisione 004:
la Sidebar è gerarchica, con gruppi espandibili.

[D] Decisione 005:
Workspace e Sidebar sono separati.

[D] DA-009:
l'Application Shell comprende Sidebar, Toolbar, Tabs,
Workspace e StatusBar opzionale.
Tutti i moduli applicativi sono ospitati nel Workspace.

[D] DA-011:
il Layout Engine organizza l'applicazione;
i componenti UI curano la rappresentazione grafica.
Un componente UI non decide il layout dell'applicazione.

[D] Il Workspace segue i principi di separazione delle
responsabilità, componibilità, riutilizzabilità, coerenza
e semplicità.

[P] Applicare le convenzioni alle nuove parti PFW.
Non rinominare automaticamente classi, modelli o componenti
esistenti non conformi durante interventi non correlati.
Le classi di librerie esterne mantengono i propri nomi.

## 5. Regole C# e Razor Pages

[P] Conservare nullable reference types e distinguere
esplicitamente valori assenti, stringhe vuote e valori zero.

[C/P] Seguire il modello asincrono dei repository:
metodi con suffisso Async e propagazione del CancellationToken.

[P] Rilasciare connessioni, comandi, reader e stream tramite
using o await using.

[P] Utilizzare decimal per importi, costi e quantità coerentemente
con i modelli esistenti; non introdurre conversioni a floating point
che alterino precisione o arrotondamenti.

[P] Nei PageModel gestire binding, validazione e orchestrazione.
Mantenere SQL nei repository e rendering nei file Razor.

[P] Validare sul server:
- identificativi;
- esistenza delle entità;
- appartenenza di ciascun elemento al proprio contesto;
- dati modificabili dall'utente.

[P] Non fidarsi dei soli identificativi ricevuti da route,
query string o campi nascosti.

[P] Utilizzare ModelState per gli errori di input e ricaricare
le liste necessarie quando si ripresenta il form.

[D] Gli errori funzionali prevedibili devono essere intercettati
nella UI e mostrati con messaggi comprensibili, senza Developer
Exception Page o dettagli tecnici. Le eccezioni impreviste restano
gestite dal normale error handling e logging globale.

[P] Eseguire le modifiche tramite POST, mantenendo le protezioni
antiforgery di Razor Pages. Un GET non deve eliminare dati.

[P] Utilizzare i meccanismi Razor di generazione dei collegamenti
e verificare che le destinazioni esistano.
Accettare URL di ritorno soltanto se locali.

[P] Non aggiungere azioni apparentemente operative prive
di implementazione. Separare chiaramente le pagine dimostrative
dalle funzionalità applicative.

## 6. Gerarchia funzionale del preventivo

[C] La navigazione operativa di riferimento è:

Preventivo
└── Righe
    └── Componenti
        ├── Materiali
        │   └── Allegati
        ├── Lavorazioni
        │   └── Allegati
        └── Allegati

[C] Esistono inoltre allegati della testata preventivo
e allegati di altre entità, come i clienti.

[C] Il preventivo dispone anche della gestione varianti.
Non confondere varianti, righe e componenti.

[C] Il Workspace della riga mostra i componenti.
Il dettaglio del componente espone materiali, lavorazioni
e allegati.

[C] Origini disponibili nel codice:
- componenti: Distinta, Articolo, Libero;
- materiali: Distinta, Anagrafica, Libero;
- lavorazioni: Distinta, Anagrafica, Libero.

[P] Conservare queste possibilità quando si interviene sui flussi,
senza aggiungere nuovi significati funzionali non documentati.

### Limite tecnico da rispettare

[C] Materiali e lavorazioni utilizzano IdRigaPreventivo
e IdNodoDistinta nullable.
Il relativo contratto non contiene un collegamento diretto
a IdRigaCompPrev.

[P] Non equiparare IdNodoDistinta e IdRigaCompPrev.
Non assumere che il filtro per nodo identifichi sempre
un componente univoco.

[P] Prima di modificare associazioni o schema, chiarire il
comportamento per componenti liberi, nodi nulli o nodi condivisi.

[P] Verificare l'intera catena di appartenenza:
Preventivo -> Riga -> Componente -> elemento interessato.

[P] Non inventare formule di costo, margine, prezzo, quantità
calcolata, propagazione delle varianti o cancellazione a cascata.
Conservare i contratti esistenti e segnalare le decisioni mancanti.

## 7. Gestione allegati

[C] L'associazione degli allegati è basata su Entita e IdEntita.

[C] Tra le chiavi utilizzate figurano:
- Clienti;
- Preventivi;
- PreventiviRigheComponenti;
- PreventiviRigheMateriali;
- PreventiviRigheLavorazioni.

[P] Conservare le chiavi tecniche esistenti.
Non rinominarle come semplice modifica di etichette UI.

[C] I file sono conservati su filesystem.
Nel database sono registrati i metadati, inclusi nome originale,
nome archiviato, percorso relativo, estensione e dimensione.

[C] Organizzazione dello storage:
<root>/<Entita>/<anno>/<IdEntita>/<GUID><estensione>

[C] La root effettiva è letta dal parametro SQL
PercorsoRootAllegati.
Il servizio segnala errore quando il parametro manca.

[C] StorageOptions.ArchivioAllegati è ancora presente e registrato,
ma il servizio corrente usa PercorsoRootAllegati.

[P] Non introdurre fallback fra le due configurazioni
senza una decisione esplicita.

[C] L'upload utilizza un file temporaneo; il flusso corrente
prevede la sua rimozione nel blocco finally.

[C] Apertura e cancellazione utilizzano i servizi applicativi
e di storage. L'upload corrente orchestra storage e repository
nel PageModel Nuovo.

[C] La cancellazione corrente è fisica:
prima il file, poi il record SQL.
Non è una disattivazione logica.

[D] La gestione Allegati prevede eliminazione fisica del file
dallo storage e cancellazione definitiva del record da dbo.Allegati,
in deroga alla disattivazione logica.

[P] Non cambiare implicitamente questa semantica.
Non estendere la cancellazione agli allegati delle entità figlie
senza verificarne il requisito.

[P] Non presumere atomicità fra filesystem e SQL Server.
Per interventi su upload o eliminazione considerare esplicitamente
fallimenti parziali, file orfani e metadati privi di file.

[P] Validare i percorsi e assicurare che rimangano all'interno
della root configurata. Non utilizzare percorsi arbitrari
forniti dal client.

[P] Limiti di dimensione, estensioni ammesse, conservazione,
versionamento e permessi richiedono requisiti espliciti:
non considerarli già decisi.

## 8. Parametri di sistema

[D] dbo.ParametriSistema è la fonte centralizzata dei parametri
gestionali. Non aggiungere DataUltimaModifica e UtenteUltimaModifica
a dbo.ParametriSistema.

[C] I parametri sono letti attraverso IParametriSistemaRepository
e dbo.ParametriSistema_GetValore.

[C] GetValoreAsync restituisce un valore testuale nullable.

[C] Lo script versionato per TipoDato prevede:
Stringa, Intero, Decimale, Booleano e Data.

[P] La presenza di TipoDato nello script non dimostra
l'esistenza di conversioni tipizzate automatiche nel codice.

[P] Conservare le chiavi tecniche già utilizzate.
Validare assenza, formato e conversione dei valori nel punto
appropriato, evitando default silenziosi non concordati.

[P] Ogni nuovo parametro deve indicare:
- chiave;
- significato;
- tipo;
- obbligatorietà;
- eventuale default approvato;
- comportamento in caso di valore mancante o non valido.

[P] Versionare gli script necessari alla definizione o
inizializzazione dei parametri.
Non inserire credenziali o valori riservati negli script.

## 9. SQL Server e conservazione degli script

[D] Ogni modifica al database deve avere il relativo script SQL.

[D] Nessuna modifica deve rimanere soltanto sul server SQL.
Gli script devono essere conservati nel repository e versionati.

[D] Gli script devono essere idempotenti quando possibile.

[D] L'organizzazione prevista da database/README.md è:
- 00_Installazione;
- 01_Tabelle;
- 02_Viste;
- 03_StoredProcedure;
- 04_Funzioni;
- 05_DatiIniziali;
- 06_Aggiornamenti.

[C] L'accesso dati applicativo utilizza ADO.NET,
Microsoft.Data.SqlClient e stored procedure.

[P] Riutilizzare SqlConnectionFactory, DatabaseExecutor
e i repository esistenti dove appropriato.

[P] Utilizzare parametri SQL; non concatenare input utente
nel testo dei comandi.
Definire tipi, dimensioni e precisioni coerenti con SQL Server.

[P] Mantenere allineati parametri, colonne restituite,
modelli C# e mapping.

[P] Per ogni modifica a tabelle, viste, procedure, funzioni,
vincoli o dati di configurazione, includere gli script necessari
nella stessa consegna del codice dipendente.

[P] Specificare prerequisiti, ordine di esecuzione e impatto
sui dati. Se uno script non è ripetibile, dichiararlo.

[P] Non eseguire indiscriminatamente tutti gli script
in ordine alfabetico: il repository contiene anche script
storici di creazione e successiva rimozione.

[P] Non ricostruire per supposizione procedure mancanti.
Segnalare la lacuna e acquisire una definizione attendibile
nell'ambito autorizzato.

[P] Non dichiarare riproducibile da zero il database finché
schema e dipendenze non sono stati verificati.

## 10. Compilazione e test

[P] Per modifiche al codice, compilare la soluzione:

Dalla radice del repository:
    dotnet build src/Preventivi.Web.slnx

Dalla cartella src:
    dotnet build Preventivi.Web.slnx

[P] Riportare errori e warning effettivamente rilevati,
distinguendo quelli preesistenti da quelli introdotti.
Non dichiarare una compilazione riuscita senza averla eseguita.

[C] Nella baseline non sono presenti progetti di test
automatizzati versionati. Le pagine Dev e TestDb non sono
una suite automatizzata.

[P] Eseguire gli eventuali test disponibili dopo le modifiche.
Aggiungere verifiche mirate per regole, regressioni e casi
di errore rilevanti, evitando test che duplicano soltanto
l'implementazione.

[P] Per modifiche ai flussi verificare, secondo l'ambito:
- navigazione e ritorno al contesto corretto;
- validazioni;
- appartenenza degli elementi alla gerarchia;
- inserimento ed eliminazione;
- apertura, download e rimozione degli allegati;
- gestione dei parametri mancanti.

[P] Eseguire prove con scritture soltanto su ambienti di test
identificati e nell'ambito autorizzato.

[P] La compilazione C# non verifica l'esistenza o la correttezza
delle stored procedure sul server.

[P] Nelle attività esclusivamente documentali o di analisi,
rispettare eventuali richieste di non modificare file.
Non eseguire build o test che generino artefatti se incompatibili
con tale vincolo.

## 11. Git e modifiche al database

[P] Prima di lavorare verificare radice del repository,
branch, commit e stato del working tree.

[P] Quando si richiede un riferimento all'ultimo push,
verificare il commit remoto oppure dichiarare esplicitamente
che il controllo riguarda solo il riferimento remoto locale.

[P] Conservare le modifiche dell'utente.
Non eseguire reset, pulizie distruttive o ripristini generali
per semplificare il lavoro.

[P] Mantenere le modifiche limitate all'obiettivo richiesto.
Esaminare il diff prima della consegna.

[P] Commit e push richiedono una richiesta esplicita.
Preparare lo staging con percorsi selezionati e verificare
che includa gli script SQL necessari.

[P] Non versionare credenziali, allegati operativi,
backup contenenti dati o artefatti di compilazione.

[P] La preparazione di uno script non implica il permesso
di eseguirlo su un database.

[P] Prima di applicare modifiche SQL verificare:
- server e database di destinazione;
- ambiente interessato;
- autorizzazione dell'intervento;
- prerequisiti e impatto sui dati.

[P] Per operazioni distruttive o migrazioni con rischio di
perdita dati, definire protezione dei dati e modalità di recupero
prima dell'esecuzione.

[P] Non affermare che una modifica SQL è applicata o verificata
se è stato soltanto scritto lo script.

## 12. Decisioni ancora da formalizzare

Alla baseline richiedono chiarimento documentale:
- associazione univoca dei materiali e delle lavorazioni
  ai componenti, soprattutto senza nodo distinta;
- formule economiche e regole di ricalcolo;
- comportamento delle varianti;
- cancellazioni a cascata;
- politiche di sicurezza e conservazione degli allegati;
- gestione dei fallimenti fra filesystem e database;
- configurazione definitiva dello storage;
- eccezioni alle convenzioni di naming e CSS;
- convergenza fra Partial, ViewComponent e TagHelper;
- completamento degli script SQL e procedura di installazione;
- workflow Git e strategia di test condivisi.

[P] Non colmare queste lacune introducendo decisioni
funzionali implicite. Registrare le nuove decisioni soltanto
quando effettivamente concordate.

[D] Documentare le nuove decisioni approvate nel registro decisioni
del repository, distinguendo decisioni, implementazioni e proposte.
Alla baseline il registro presente è docs/08-Decisioni-Architetturali.md.

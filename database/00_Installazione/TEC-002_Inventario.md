# TEC-002 - Inventario schema estratto

Estrazione in sola lettura. Dati, utenti, ruoli, permessi e credenziali sono esclusi.

## Oggetti

- Tabelle: 49
- Colonne: 517
- Chiavi primarie: 48
- Chiavi esterne: 75
- Vincoli default: 161
- Vincoli check: 20
- Strutture indicizzate: 101
- Viste: 26
- Stored procedure: 74
- Tipi dato definiti dall'utente: 0
- Tipi tabella definiti dall'utente: 0
- Sequenze: 0

## File

- `01_Tabelle/TEC-002_01_Tabelle.sql` - SHA-256 `81aa0b69cd02a003e7b598256eacdd613339ed6bcd4fdd3f08896fc8012b4684`
- `01_Tabelle/TEC-002_02_ChiaviEsterne.sql` - SHA-256 `9cdb0061b72f778e8a42cb5596cca4fdc37f30b003f86c331f45cfb3d84b6bf0`
- `02_Viste/TEC-002_03_Viste.sql` - SHA-256 `b5969315f3ce9da32f6e6af88bb0259be1b4fa3a018e412c3cf83e0ec1282825`
- `03_StoredProcedure/TEC-002_04_StoredProcedure.sql` - SHA-256 `f0f394a9971b50e3ba1c07138f366719cff27d1cd76cc26396dc99654fb6cdec`

I percorsi sono relativi alla cartella `database`.

## Verifiche eseguite

- conteggi DDL confrontati con l'inventario dello schema installato;
- nessuna vista o stored procedure duplicata nei file estratti;
- parsing T-SQL 140 completato senza errori sui quattro script;
- nessuna istruzione `USE` e nessuna stringa di connessione o credenziale;
- nessun dato operativo esportato.

## Collaudo di installazione

Il 16 ottobre 2026 i quattro script sono stati eseguiti nell'ordine
documentato su un database temporaneo vuoto. Il collaudo ha verificato:

- la corrispondenza di tutti i conteggi dell'inventario;
- il completamento di `sp_refreshview` per tutte le 26 viste;
- il completamento di `sp_refreshsqlmodule` per tutte le 74 procedure;
- il completamento di `DBCC CHECKDB` senza errori;
- l'eliminazione del database temporaneo al termine del test;
- l'assenza di database temporanei TEC-002 residui sul server.

La riproducibilita esecutiva dello schema e pertanto verificata. Restano
esclusi dal perimetro i dati iniziali e la verifica funzionale
dell'applicazione sul database vuoto.

# 03 - Workspace

## Scopo

Il Workspace definisce la struttura standard di qualsiasi applicazione costruita con il Preventivi Framework (PFW).

Il suo obiettivo è separare completamente:

- navigazione;
- layout;
- componenti grafici;
- logica applicativa.

Ogni modulo dell'applicazione (Preventivi, Clienti, Articoli, WMS, K-Count, ecc.) dovrà limitarsi a fornire dati e comportamenti, delegando al Workspace la costruzione dell'interfaccia utente.

Il Workspace costituisce, insieme alla Sidebar, l'Application Shell del framework.

## Principi

L'Application Shell del PFW segue cinque principi fondamentali.

### 1. Separazione delle responsabilità

Ogni componente svolge un solo compito.

### 2. Componibilità

Ogni componente può contenere altri componenti.

### 3. Riutilizzabilità

Il framework non contiene logiche di dominio.

### 4. Coerenza

Ogni pagina utilizza sempre lo stesso layout.

### 5. Semplicità

L'interfaccia privilegia leggibilità, velocità e chiarezza rispetto agli effetti grafici.
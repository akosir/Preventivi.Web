Decisione 001
Il PFW utilizza Razor Partial come componente base.

Decisione 002
I Model sono in italiano.

Decisione 003
Le classi CSS utilizzano prefisso pfw-.

Decisione 004
Sidebar gerarchica con gruppi espandibili.

Decisione 005
Workspace separato dalla Sidebar.

## DA-009

Il Preventivi Framework utilizza un'Application Shell composta da:

- Sidebar
- Toolbar
- Tabs
- Workspace
- StatusBar (opzionale)

Tutti i moduli applicativi devono essere ospitati all'interno del Workspace.

L'Application Shell costituisce il layout standard del framework.

DA-011

Il Preventivi Framework è suddiviso in due macro aree:

1. Layout Engine
2. UI Components

Il Layout Engine è responsabile
esclusivamente dell'organizzazione
dell'applicazione.

I Componenti UI sono responsabili
esclusivamente della rappresentazione
grafica.

Nessun componente UI può decidere
il layout dell'applicazione.
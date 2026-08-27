using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Web.UI.KPI;
using Preventivi.Web.UI.Modules.Dashboard;

namespace Preventivi.Web.Pages.Dashboard;

public class IndexModel : PageModel
{
    public DashboardHeaderModel Header { get; private set; }
        = new();

    public DashboardKpiRowModel Kpi { get; private set; }
        = new();

    public DashboardRecentActivityModel AttivitaRecenti { get; private set; }
    = new();

    public DashboardDeadlinesModel Scadenze { get; private set; }
    = new();

    public DashboardTodoModel DaFare { get; private set; } = new();

    public DashboardQuickLinksModel CollegamentiRapidi { get; private set; }
    = new();

    public IActionResult OnGet()
    {
        return RedirectToPage("/Index");
    }

    private void CreaDashboardDemo()
    {
        Header = new DashboardHeaderModel
        {
            Titolo = "Dashboard",

            Sottotitolo =
                "Situazione operativa generale",

            DataTesto =
                DateTime.Now.ToString(
                    "dddd d MMMM yyyy"),

            UltimoAggiornamento =
                DateTime.Now.ToString("HH:mm")
        };

        Kpi = new DashboardKpiRowModel
        {
            Elementi =
            [
                new PFWKPIModel
                {
                    Titolo = "Preventivi aperti",
                    Valore = "18",
                    Sottotitolo = "Preventivi attualmente aperti",
                    Variante = "primario"
                },

                new PFWKPIModel
                {
                    Titolo = "In ritardo",
                    Valore = "4",
                    Sottotitolo = "Richiedono attenzione",
                    Variante = "errore"
                },

                new PFWKPIModel
                {
                    Titolo = "Richieste cliente",
                    Valore = "11",
                    Sottotitolo = "Richieste aperte",
                    Variante = "informazione"
                },

                new PFWKPIModel
                {
                    Titolo = "Ordini fornitori",
                    Valore = "7",
                    Sottotitolo = "Ordini ancora aperti",
                    Variante = "attenzione"
                }
            ]
        };

        AttivitaRecenti = new DashboardRecentActivityModel
        {
            Titolo = "Attività recenti",

            Sottotitolo = "Ultime operazioni effettuate",

            Elementi =
    [
        new()
        {
            Titolo = "Preventivo aggiornato",
            Dettaglio = "Aggiornata una voce del documento",
            DataOra = "09:42",
            Variante = "informazione"
        },

        new()
        {
            Titolo = "Nuova richiesta",
            Dettaglio = "Inserita una nuova richiesta cliente",
            DataOra = "09:18",
            Variante = "primario"
        },

        new()
        {
            Titolo = "Ordine inviato",
            Dettaglio = "Ordine fornitore trasmesso",
            DataOra = "08:55",
            Variante = "successo"
        }
    ]
        };
        Scadenze = new DashboardDeadlinesModel
        {
            Titolo = "Scadenze",

            Sottotitolo = "Attività imminenti",

            Elementi =
    [
        new()
        {
            Titolo = "Preventivo da completare",
            Dettaglio = "Documento in attesa di verifica",
            Scadenza = "Oggi",
            Variante = "errore"
        },

        new()
        {
            Titolo = "Campionatura aperta",
            Dettaglio = "Verifica esito campionatura",
            Scadenza = "Domani",
            Variante = "attenzione"
        },

        new()
        {
            Titolo = "Richiesta cliente",
            Dettaglio = "Preparare risposta commerciale",
            Scadenza = "2 giorni",
            Variante = "informazione"
        }
    ]
        };
        DaFare = new DashboardTodoModel
        {
            Titolo = "Da fare",

            Sottotitolo = "Attività operative",

            Elementi =
    [
        new()
        {
            Titolo = "Preventivi da completare",
            Descrizione = "Preventivi in lavorazione",
            Quantita = 7,
            Url = "#",
            VarianteBadge = "warning"
        },

        new()
        {
            Titolo = "Richieste Cliente",
            Descrizione = "Da prendere in carico",
            Quantita = 3,
            Url = "#",
            VarianteBadge = "primary"
        },

        new()
        {
            Titolo = "Offerte Fornitori",
            Descrizione = "Da inviare",
            Quantita = 5,
            Url = "#",
            VarianteBadge = "info"
        },

        new()
        {
            Titolo = "Campionature",
            Descrizione = "Da verificare",
            Quantita = 2,
            Url = "#",
            VarianteBadge = "danger"
        }
    ]
        };

        CollegamentiRapidi = new DashboardQuickLinksModel
        {
            Titolo = "Collegamenti rapidi",

            Sottotitolo = "Operazioni più frequenti",

            Elementi =
    [
        new()
        {
            Titolo = "Nuovo Preventivo",
            Url = "#"
        },

        new()
        {
            Titolo = "Nuovo Cliente",
            Url = "#"
        },

        new()
        {
            Titolo = "Nuovo Articolo",
            Url = "#"
        },

        new()
        {
            Titolo = "Nuova Richiesta Cliente",
            Url = "#"
        },

        new()
        {
            Titolo = "Nuovo Fornitore",
            Url = "#"
        }
    ]
        };
    }

}

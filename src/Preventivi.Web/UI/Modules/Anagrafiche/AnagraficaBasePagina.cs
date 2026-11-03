using Preventivi.Core.Anagrafiche;

namespace Preventivi.Web.UI.Modules.Anagrafiche;

public sealed record AnagraficaBasePagina(
    TipoAnagraficaBase Tipo,
    string Chiave,
    string Titolo,
    string TitoloSingolare,
    bool MostraCodice,
    int LunghezzaCodice,
    int LunghezzaDescrizione)
{
    public static bool TryGet(string? chiave, out AnagraficaBasePagina pagina)
    {
        pagina = chiave?.ToLowerInvariant() switch
        {
            "unita-misura" => new(
                TipoAnagraficaBase.UnitaMisura,
                "unita-misura",
                "Unita di misura",
                "unita di misura",
                true,
                10,
                50),
            "tipi-nodo-distinta" => new(
                TipoAnagraficaBase.TipiNodoDistinta,
                "tipi-nodo-distinta",
                "Tipi nodo distinta",
                "tipo nodo distinta",
                false,
                0,
                100),
            _ => null!
        };

        return pagina is not null;
    }
}

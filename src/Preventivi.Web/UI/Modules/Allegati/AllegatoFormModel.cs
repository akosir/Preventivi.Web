using Microsoft.AspNetCore.Http;
using Preventivi.Core.Allegati;

namespace Preventivi.Web.UI.Modules.Allegati;

public sealed class AllegatoFormModel
{
    public string TipoAllegato { get; set; } = "";

    public string? Descrizione { get; set; }

    public string? Note { get; set; }

    public IFormFile? File { get; set; }

    public IReadOnlyList<TipoAllegatoItem> TipiAllegato { get; set; }
     = Array.Empty<TipoAllegatoItem>();
}
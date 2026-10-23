using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Preventivi;
using Preventivi.Web.UI.Modules.Preventivi;

namespace Preventivi.Web.Pages.Preventivi.Modelli.Righe;

public abstract class ModelloPreventivoRigaPageBase : PageModel
{
    protected IModelloPreventivoRepository ModelloRepository { get; }
    protected IPreventivoRepository PreventivoRepository { get; }

    protected ModelloPreventivoRigaPageBase(
        IModelloPreventivoRepository modelloRepository,
        IPreventivoRepository preventivoRepository)
    {
        ModelloRepository = modelloRepository;
        PreventivoRepository = preventivoRepository;
    }

    public ModelloPreventivoDettaglio? Modello { get; protected set; }

    public IReadOnlyList<TipoRigaPreventivoItem> TipiRiga { get; protected set; }
        = Array.Empty<TipoRigaPreventivoItem>();

    public IReadOnlyList<ArticoloLookupItem> Articoli { get; protected set; }
        = Array.Empty<ArticoloLookupItem>();

    public IReadOnlyList<ModelloCicloLookupItem> ModelliCiclo { get; protected set; }
        = Array.Empty<ModelloCicloLookupItem>();

    protected async Task<bool> CaricaModelloAsync(
        int idModello,
        CancellationToken cancellationToken)
    {
        Modello = await ModelloRepository.GetDettaglioAsync(idModello, cancellationToken);
        return Modello is not null;
    }

    protected async Task CaricaLookupAsync(CancellationToken cancellationToken)
    {
        TipiRiga = await PreventivoRepository.GetTipiRigaAsync(cancellationToken);
        Articoli = await PreventivoRepository.CercaArticoliAsync(null, cancellationToken);
        ModelliCiclo = await PreventivoRepository.GetModelliCicloAsync(cancellationToken);
    }

    protected void ValidaRiga(
        ModelloPreventivoRigaFormModel dati,
        ModelStateDictionary modelState)
    {
        var tipo = TipiRiga.FirstOrDefault(item => item.IdTipoRiga == dati.IdTipoRiga);
        if (tipo is null)
        {
            modelState.AddModelError("Dati.IdTipoRiga", "Selezionare un tipo riga disponibile.");
            return;
        }

        if (tipo.RigaArticolo)
        {
            if (tipo.ObbligaArticolo && !dati.IdArticolo.HasValue)
                modelState.AddModelError("Dati.IdArticolo", "Selezionare un articolo.");
            else if (dati.IdArticolo.HasValue &&
                     Articoli.All(item => item.IdArticolo != dati.IdArticolo.Value))
                modelState.AddModelError("Dati.IdArticolo", "L'articolo selezionato non e disponibile.");

            if (dati.IdModelloCiclo.HasValue &&
                ModelliCiclo.All(item => item.IdModelloCiclo != dati.IdModelloCiclo.Value))
                modelState.AddModelError("Dati.IdModelloCiclo", "Il modello ciclo selezionato non e disponibile.");
        }
        else
        {
            dati.IdArticolo = null;
            dati.IdModelloCiclo = null;
        }
    }

    protected ModelloPreventivoRigaFormViewModel CreaForm(
        ModelloPreventivoRigaFormModel dati) =>
        new(dati, TipiRiga, Articoli, ModelliCiclo);

    protected static bool ErroreRigaPrevisto(int numero) =>
        numero is >= 52120 and <= 52129 or 2601 or 2627;
}

using System.ComponentModel.DataAnnotations;
using Preventivi.Web.UI.Modules.Anagrafiche;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules.Anagrafiche;

public sealed class AnagraficheProduttiveFormTests
{
    [Fact]
    public void DistintaNodo_CampiObbligatoriMancanti_NonEValido()
    {
        var risultati = Valida(new DistintaNodoFormModel());

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaNodoFormModel.IdTipoNodo)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaNodoFormModel.DescrizioneNodo)));
    }

    [Fact]
    public void DistintaMateriale_ValoriNegativi_NonEValido()
    {
        var risultati = Valida(new DistintaMaterialeFormModel
        {
            IdMateriale = 1,
            Quantita = -1m,
            CoeffScartoPerc = -1m,
            CostoUnitario = -1m
        });

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaMaterialeFormModel.Quantita)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaMaterialeFormModel.CoeffScartoPerc)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaMaterialeFormModel.CostoUnitario)));
    }

    [Fact]
    public void DistintaLavorazione_ValoriNegativi_NonEValida()
    {
        var risultati = Valida(new DistintaLavorazioneFormModel
        {
            IdLavorazione = 1,
            Sequenza = 0,
            TempoSetupMin = -1m,
            TempoPezzoMin = -1m,
            CostoOrario = -1m,
            CostoFisso = -1m
        });

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaLavorazioneFormModel.Sequenza)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaLavorazioneFormModel.TempoSetupMin)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaLavorazioneFormModel.TempoPezzoMin)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaLavorazioneFormModel.CostoOrario)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(DistintaLavorazioneFormModel.CostoFisso)));
    }

    [Fact]
    public void Articolo_CampiObbligatoriMancanti_NonEValido()
    {
        var risultati = Valida(new ArticoloFormModel());

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(ArticoloFormModel.CodiceArticolo)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(ArticoloFormModel.Descrizione)));
    }

    [Fact]
    public void Articolo_ConClienteOpzionale_EValido()
    {
        var modello = new ArticoloFormModel
        {
            CodiceArticolo = "ART-TEST",
            Descrizione = "Articolo di prova",
            Versione = "A",
            IdCliente = 1,
            NoteTecniche = "Note di collaudo"
        };

        Assert.Empty(Valida(modello));
    }

    [Fact]
    public void Materiale_CampiObbligatoriMancanti_NonEValido()
    {
        var risultati = Valida(new MaterialeFormModel());

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(MaterialeFormModel.CodiceMateriale)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(MaterialeFormModel.Descrizione)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(MaterialeFormModel.IdUM)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(MaterialeFormModel.TipoMateriale)));
    }

    [Fact]
    public void Materiale_CostoNegativo_NonEValido()
    {
        var modello = MaterialeValido();
        modello.CostoUnitario = -0.0001m;

        var risultati = Valida(modello);

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(MaterialeFormModel.CostoUnitario)));
    }

    [Fact]
    public void Lavorazione_CampiObbligatoriMancanti_NonEValida()
    {
        var risultati = Valida(new LavorazioneFormModel());

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.CodiceLavorazione)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.Descrizione)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.InternaEsterna)));
    }

    [Fact]
    public void Lavorazione_ValoriEconomiciNegativi_NonEValida()
    {
        var modello = LavorazioneValida();
        modello.CostoOrarioStandard = -1m;
        modello.TempoSetupMinDefault = -1m;
        modello.TempoPezzoMinDefault = -1m;

        var risultati = Valida(modello);

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.CostoOrarioStandard)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.TempoSetupMinDefault)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(LavorazioneFormModel.TempoPezzoMinDefault)));
    }

    private static MaterialeFormModel MaterialeValido() => new()
    {
        CodiceMateriale = "MAT-TEST",
        Descrizione = "Materiale di prova",
        IdUM = 1,
        TipoMateriale = "MateriaPrima",
        CostoUnitario = 1m
    };

    private static LavorazioneFormModel LavorazioneValida() => new()
    {
        CodiceLavorazione = "LAV-TEST",
        Descrizione = "Lavorazione di prova",
        InternaEsterna = "Interna",
        CostoOrarioStandard = 1m,
        TempoSetupMinDefault = 1m,
        TempoPezzoMinDefault = 1m
    };

    private static IReadOnlyList<ValidationResult> Valida(object modello)
    {
        var risultati = new List<ValidationResult>();
        Validator.TryValidateObject(modello, new ValidationContext(modello), risultati, true);
        return risultati;
    }
}

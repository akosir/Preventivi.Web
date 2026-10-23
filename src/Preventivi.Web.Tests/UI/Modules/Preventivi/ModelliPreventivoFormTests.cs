using System.ComponentModel.DataAnnotations;
using Preventivi.Web.UI.Modules.Preventivi;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules.Preventivi;

public sealed class ModelliPreventivoFormTests
{
    [Fact]
    public void Testata_RichiedeCodiceEDescrizione()
    {
        var risultati = Valida(new ModelloPreventivoFormModel());

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoFormModel.CodiceModelloPreventivo)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoFormModel.Descrizione)));
    }

    [Fact]
    public void Testata_AccettaIValoriMinimiValidi()
    {
        var risultati = Valida(
            new ModelloPreventivoFormModel
            {
                CodiceModelloPreventivo = "MODELLO-01",
                Descrizione = "Modello di prova"
            });

        Assert.Empty(risultati);
    }

    [Fact]
    public void Riga_RifiutaNumeroQuantitaEPrezzoNonValidi()
    {
        var risultati = Valida(
            new ModelloPreventivoRigaFormModel
            {
                RigaNr = 0,
                IdTipoRiga = 0,
                DescrizioneVoce = "Riga",
                Quantita = 0,
                PrezzoUnitarioVendita = -1
            });

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoRigaFormModel.RigaNr)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoRigaFormModel.IdTipoRiga)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoRigaFormModel.Quantita)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(ModelloPreventivoRigaFormModel.PrezzoUnitarioVendita)));
    }

    [Fact]
    public void Riga_AccettaIValoriMinimiValidi()
    {
        var risultati = Valida(
            new ModelloPreventivoRigaFormModel
            {
                RigaNr = 1,
                IdTipoRiga = 1,
                DescrizioneVoce = "Articolo di prova",
                Quantita = 1,
                PrezzoUnitarioVendita = 0
            });

        Assert.Empty(risultati);
    }

    private static IReadOnlyList<ValidationResult> Valida(object modello)
    {
        var risultati = new List<ValidationResult>();
        Validator.TryValidateObject(
            modello,
            new ValidationContext(modello),
            risultati,
            validateAllProperties: true);
        return risultati;
    }
}

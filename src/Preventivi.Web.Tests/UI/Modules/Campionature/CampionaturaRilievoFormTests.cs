using System.ComponentModel.DataAnnotations;
using Preventivi.Web.UI.Modules.Campionature;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules.Campionature;

public sealed class CampionaturaRilievoFormTests
{
    [Fact]
    public void Form_RichiedeDataTipoDescrizioneEGravita()
    {
        var risultati = Valida(new CampionaturaRilievoFormModel
        {
            Gravita = string.Empty
        });

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaRilievoFormModel.DataRilevazione)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaRilievoFormModel.IdTipoProblematica)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaRilievoFormModel.DescrizioneProblema)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaRilievoFormModel.Gravita)));
    }

    [Fact]
    public void Form_AccettaValoriMinimiValidi()
    {
        var risultati = Valida(new CampionaturaRilievoFormModel
        {
            DataRilevazione = new DateOnly(2026, 10, 29),
            IdTipoProblematica = 1,
            DescrizioneProblema = "Difetto rilevato",
            Gravita = "Media"
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

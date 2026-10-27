using System.ComponentModel.DataAnnotations;
using Preventivi.Web.UI.Modules.Campionature;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules.Campionature;

public sealed class CampionaturaFormTests
{
    [Fact]
    public void Form_RichiedeDataRichiestaEOggetto()
    {
        var risultati = Valida(new CampionaturaFormModel());

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaFormModel.DataCampionatura)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaFormModel.IdRichiestaCliente)));
        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaFormModel.Oggetto)));
    }

    [Fact]
    public void Form_RifiutaOggettoOltreLaLunghezzaMassima()
    {
        var modello = CreaValido();
        modello.Oggetto = new string('X', 251);

        var risultati = Valida(modello);

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(CampionaturaFormModel.Oggetto)));
    }

    [Fact]
    public void Form_AccettaValoriMinimiValidi()
    {
        Assert.Empty(Valida(CreaValido()));
    }

    private static CampionaturaFormModel CreaValido() => new()
    {
        DataCampionatura = new DateOnly(2026, 10, 27),
        IdRichiestaCliente = 1,
        Oggetto = "Nuovo campione",
        Stato = "Aperta",
        Priorita = "Media"
    };

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

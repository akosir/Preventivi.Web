using System.ComponentModel.DataAnnotations;
using Preventivi.Web.UI.Modules.RichiesteClienti;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules.RichiesteClienti;

public sealed class RichiestaClienteFormTests
{
    [Fact]
    public void Form_RichiedeDataClienteOggettoStatoEPriorita()
    {
        var risultati = Valida(new RichiestaClienteFormModel());

        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(RichiestaClienteFormModel.DataRichiesta)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(RichiestaClienteFormModel.IdCliente)));
        Assert.Contains(risultati, errore => errore.MemberNames.Contains(nameof(RichiestaClienteFormModel.Oggetto)));
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(101)]
    public void Form_RifiutaProbabilitaFuoriIntervallo(int probabilita)
    {
        var modello = CreaValido();
        modello.ProbabilitaChiusura = probabilita;

        var risultati = Valida(modello);

        Assert.Contains(risultati, errore =>
            errore.MemberNames.Contains(nameof(RichiestaClienteFormModel.ProbabilitaChiusura)));
    }

    [Fact]
    public void Form_AccettaValoriMinimiValidi()
    {
        Assert.Empty(Valida(CreaValido()));
    }

    private static RichiestaClienteFormModel CreaValido() => new()
    {
        DataRichiesta = new DateOnly(2026, 10, 26),
        IdCliente = 1,
        Oggetto = "Nuova richiesta",
        Stato = "Nuova",
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

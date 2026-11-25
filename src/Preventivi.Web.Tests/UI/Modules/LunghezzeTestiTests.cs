using System.ComponentModel.DataAnnotations;
using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Clienti;
using Preventivi.Core.Preventivi;
using Preventivi.Data.Clienti;
using Preventivi.Data.Comune;
using Preventivi.Data.Preventivi;
using Preventivi.Web.UI;
using Preventivi.Web.UI.Modules.Clienti;
using Xunit;

namespace Preventivi.Web.Tests.UI.Modules;

public sealed class LunghezzeTestiTests
{
    public static IEnumerable<object[]> Campi()
    {
        var clienti = new[] { ("CodiceCliente", 30), ("RagioneSociale", 150), ("PartitaIVA", 20),
            ("CodiceFiscale", 20), ("Indirizzo", 150), ("CAP", 10), ("Citta", 100),
            ("Provincia", 10), ("Telefono", 50), ("Email", 150) };
        foreach (var tipo in new[] { typeof(ClienteFormModel), typeof(ClienteCreateModel), typeof(ClienteUpdateModel) })
            foreach (var (campo, massimo) in clienti) yield return [tipo, campo, massimo];
        foreach (var tipo in new[] { typeof(PreventivoCreateModel), typeof(PreventivoUpdateModel) })
            yield return [tipo, "Oggetto", 250];
        foreach (var tipo in new[] { typeof(PreventivoRigaCreateModel), typeof(PreventivoRigaUpdateModel) })
            yield return [tipo, "DescrizioneVoce", 250];
        foreach (var tipo in new[] { typeof(PreventivoRigaComponenteCreateModel), typeof(PreventivoRigaComponenteUpdateModel) })
            yield return [tipo, "DescrizioneNodo", 200];
        foreach (var tipo in new[] { typeof(PreventivoRigaMaterialeCreateModel), typeof(PreventivoRigaMaterialeUpdateModel) })
        {
            yield return [tipo, "DescrizioneMateriale", 200];
            yield return [tipo, "TipoMateriale", 30];
            yield return [tipo, "UM", 10];
        }
        foreach (var tipo in new[] { typeof(PreventivoRigaLavorazioneCreateModel), typeof(PreventivoRigaLavorazioneUpdateModel) })
            yield return [tipo, "DescrizioneLavorazione", 150];
        yield return [typeof(PreventivoVarianteCreateModel), "CodiceVariante", 30];
        yield return [typeof(PreventivoVarianteCreateModel), "DescrizioneVariante", 250];
    }

    [Theory, MemberData(nameof(Campi))]
    public void Limite_AccettaTestoCompletoERifiutaEccedenzaSenzaTroncare(Type tipo, string campo, int massimo)
    {
        var modello = Activator.CreateInstance(tipo)!;
        var proprieta = tipo.GetProperty(campo)!;
        var limite = proprieta.GetCustomAttribute<StringLengthAttribute>()!;
        Assert.Equal(massimo, limite.MaximumLength);
        Assert.True(limite.IsValid(new string('x', massimo - 1)));
        Assert.True(limite.IsValid(new string('x', massimo)));
        var testo = new string('x', massimo + 1);
        proprieta.SetValue(modello, testo);
        var stato = new ModelStateDictionary();
        stato.SetModelValue("Dati." + campo, testo, testo);
        stato.ValidaLunghezzeTesto(modello, "Dati");
        Assert.False(stato.IsValid);
        Assert.Equal(testo, proprieta.GetValue(modello));
        Assert.Equal(testo, stato["Dati." + campo]!.AttemptedValue);
        Assert.Contains(massimo.ToString(), Assert.Single(stato["Dati." + campo]!.Errors).ErrorMessage);
    }

    [Fact]
    public void DatiDaLookup_RipeteControlloDopoRimozioneModelState()
    {
        var modello = new PreventivoRigaLavorazioneCreateModel { DescrizioneLavorazione = new string('x', 200) };
        var stato = new ModelStateDictionary();
        stato.Remove("NuovaLavorazione.DescrizioneLavorazione");
        stato.ValidaLunghezzeTesto(modello, "NuovaLavorazione");
        Assert.False(stato.IsValid);
        Assert.Equal(200, modello.DescrizioneLavorazione.Length);
    }

    [Theory]
    [InlineData(false)] [InlineData(true)]
    public async Task Clienti_TestoLungoNonSalvaEConservaIlForm(bool modifica)
    {
        var cliente = new ClienteFormModel { CodiceCliente = new string('C', 31), RagioneSociale = "Prova" };
        if (modifica)
        {
            var pagina = new Web.Pages.Clienti.DettaglioModel(null!, null!) { Cliente = cliente, IdCliente = 1 };
            Assert.IsType<PageResult>(await pagina.OnPostAsync(default));
            Assert.Equal(cliente.CodiceCliente, pagina.Cliente.CodiceCliente);
            Assert.False(pagina.ModelState.IsValid);
        }
        else
        {
            var pagina = new Web.Pages.Clienti.NuovoModel(null!) { Cliente = cliente };
            Assert.IsType<PageResult>(await pagina.OnPostAsync(default));
            Assert.Equal(cliente.CodiceCliente, pagina.Cliente.CodiceCliente);
            Assert.False(pagina.ModelState.IsValid);
        }
    }

    [Theory]
    [InlineData(false)] [InlineData(true)]
    public async Task Clienti_RepositoryRifiutaPrimaDiAprireConnessione(bool modifica)
    {
        var repository = new ClienteRepository(new SqlConnectionFactory("NON_VALIDA"));
        if (modifica)
            await Assert.ThrowsAsync<ValidationException>(() => repository.AggiornaAsync(new ClienteUpdateModel { Email = new string('x', 151) }));
        else
            await Assert.ThrowsAsync<ValidationException>(() => repository.CreaAsync(new ClienteCreateModel { RagioneSociale = new string('x', 151) }));
    }

    [Theory]
    [InlineData("riga")] [InlineData("componente")] [InlineData("materiale")]
    [InlineData("lavorazione")] [InlineData("variante")]
    public async Task Preventivi_RepositoryNonTroncaTestiInCreazioneEModifica(string elemento)
    {
        var repository = new PreventivoRepository(new DatabaseExecutor(new SqlConnectionFactory("NON_VALIDA")));
        Func<Task> crea = elemento switch
        {
            "riga" => () => repository.CreaRigaAsync(new() { DescrizioneVoce = new string('x', 251) }),
            "componente" => () => repository.CreaComponenteAsync(new() { DescrizioneNodo = new string('x', 201) }),
            "materiale" => () => repository.CreaMaterialeAsync(new() { DescrizioneMateriale = new string('x', 201) }),
            "lavorazione" => () => repository.CreaLavorazioneAsync(new() { DescrizioneLavorazione = new string('x', 151) }),
            _ => () => repository.CreaVarianteAsync(new() { CodiceVariante = new string('x', 31) })
        };
        Func<Task> modifica = elemento switch
        {
            "riga" => () => repository.AggiornaRigaAsync(new() { DescrizioneVoce = new string('x', 251) }),
            "componente" => () => repository.AggiornaComponenteAsync(new() { DescrizioneNodo = new string('x', 201) }),
            "materiale" => () => repository.AggiornaMaterialeAsync(new() { DescrizioneMateriale = new string('x', 201) }),
            "lavorazione" => () => repository.AggiornaLavorazioneAsync(new() { DescrizioneLavorazione = new string('x', 151) }),
            _ => () => repository.AggiornaVarianteAsync(1, 2, new string('x', 31), "Prova", null, "impronta", false)
        };
        await Assert.ThrowsAsync<ValidationException>(crea);
        await Assert.ThrowsAsync<ValidationException>(modifica);
    }
}

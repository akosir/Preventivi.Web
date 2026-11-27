using System.Reflection;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Anagrafiche;
using Preventivi.Data.Anagrafiche;
using Xunit;

namespace Preventivi.Data.Tests.Preventivi;

public sealed class DistintaImportazioneServiceTests
{
    [Theory]
    [InlineData("id")] [InlineData("distinta")] [InlineData("versione")]
    [InlineData("nome")] [InlineData("estensione")] [InlineData("hash")]
    [InlineData("utente")] [InlineData("nodi")]
    public async Task MetadatiNonValidi_NonInoltraAlRepository(string campo)
    {
        var repo = DispatchProxy.Create<IDistintaBaseRepository, Repository>();
        var proxy = (Repository)(object)repo;
        var servizio = new DistintaBaseApplicationService(repo, null!, null!, NullLogger<DistintaBaseApplicationService>.Instance);
        await Assert.ThrowsAsync<ArgumentException>(() => servizio.ImportaAsync(Richiesta(campo)));
        Assert.Equal(0, proxy.Scritture);
    }

    [Fact]
    public async Task RichiestaValida_ConservaContestoVersioneEValori()
    {
        var repo = DispatchProxy.Create<IDistintaBaseRepository, Repository>();
        var proxy = (Repository)(object)repo;
        var servizio = new DistintaBaseApplicationService(repo, null!, null!, NullLogger<DistintaBaseApplicationService>.Instance);
        var richiesta = Richiesta("");
        await servizio.ImportaAsync(richiesta);
        Assert.Equal(1, proxy.Scritture); Assert.Same(richiesta, proxy.Richiesta);
    }

    private static DistintaImportazioneRequest Richiesta(string errore) => new()
    {
        IdImportazione = errore == "id" ? Guid.Empty : Guid.NewGuid(),
        IdRevisioneDistinta = errore == "distinta" ? 0 : 11,
        VersioneRiga = errore == "versione" ? [1] : new byte[8],
        NomeFile = errore == "nome" ? new string('x', 261) : errore == "estensione" ? "dati.xls" : "Distinta.xlsx",
        ImprontaSha256 = new string(errore == "hash" ? 'Z' : 'A', 64),
        Utente = errore == "utente" ? "" : "admin",
        Nodi = errore == "nodi" ? [] : [new() { ChiaveNodo = "R", DescrizioneNodo = "Radice", TipoNodo = "Prodotto finito", QuantitaBase = 1 }]
    };

    public class Repository : DispatchProxy
    {
        public int Scritture;
        public DistintaImportazioneRequest? Richiesta;
        protected override object? Invoke(MethodInfo? method, object?[]? args)
        {
            if (method!.Name != "ImportaAsync") throw new InvalidOperationException(method.Name);
            Scritture++; Richiesta = (DistintaImportazioneRequest)args![0]!;
            return Task.CompletedTask;
        }
    }
}

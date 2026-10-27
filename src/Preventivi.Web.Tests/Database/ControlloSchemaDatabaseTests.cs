using Microsoft.AspNetCore.Http;
using Preventivi.Core.Database;
using Preventivi.Web.Database;
using Xunit;

namespace Preventivi.Web.Tests.Database;

public sealed class ControlloSchemaDatabaseTests
{
    [Fact]
    public void Valuta_VersioneSupportata_RendeApplicazioneOperativa()
    {
        var stato = StatoSchemaDatabase.Valuta(
            SchemaDatabaseSupportato.Versione,
            SchemaDatabaseSupportato.CodiceIntervento);

        Assert.True(stato.Operativo);
        Assert.Equal(
            CompatibilitaSchemaDatabase.Compatibile,
            stato.Compatibilita);
    }

    [Theory]
    [InlineData(null, CompatibilitaSchemaDatabase.NonInizializzato)]
    [InlineData(2026102600, CompatibilitaSchemaDatabase.Obsoleto)]
    [InlineData(2026102703, CompatibilitaSchemaDatabase.Futuro)]
    public void Valuta_VersioneNonSupportata_BloccaApplicazione(
        int? versione,
        CompatibilitaSchemaDatabase compatibilitaAttesa)
    {
        var stato = StatoSchemaDatabase.Valuta(versione, "TEST");

        Assert.False(stato.Operativo);
        Assert.Equal(compatibilitaAttesa, stato.Compatibilita);
    }

    [Fact]
    public async Task Middleware_SchemaObsoleto_ReindirizzaAllaManutenzione()
    {
        var statoApplicazione = new StatoSchemaDatabaseApplicazione();
        statoApplicazione.Aggiorna(
            StatoSchemaDatabase.Valuta(2026102600, "PRECEDENTE"));
        var chiamataSuccessiva = false;
        var middleware = new ControlloSchemaDatabaseMiddleware(_ =>
        {
            chiamataSuccessiva = true;
            return Task.CompletedTask;
        });
        var context = new DefaultHttpContext();
        context.Request.Path = "/Preventivi";

        await middleware.InvokeAsync(context, statoApplicazione);

        Assert.False(chiamataSuccessiva);
        Assert.Equal(
            ControlloSchemaDatabaseMiddleware.PercorsoManutenzione,
            context.Response.Headers.Location.ToString());
    }

    [Fact]
    public async Task Middleware_PaginaManutenzione_NonCreaCicloDiRedirect()
    {
        var statoApplicazione = new StatoSchemaDatabaseApplicazione();
        var chiamataSuccessiva = false;
        var middleware = new ControlloSchemaDatabaseMiddleware(_ =>
        {
            chiamataSuccessiva = true;
            return Task.CompletedTask;
        });
        var context = new DefaultHttpContext();
        context.Request.Path =
            ControlloSchemaDatabaseMiddleware.PercorsoManutenzione;

        await middleware.InvokeAsync(context, statoApplicazione);

        Assert.True(chiamataSuccessiva);
    }
}

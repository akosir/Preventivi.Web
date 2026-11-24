using System.ComponentModel.DataAnnotations;
using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.OrdiniFornitori;
using Preventivi.Web.Pages.OrdiniFornitori;
using Preventivi.Web.UI.Modules.OrdiniFornitori;
using Xunit;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class OrdiniFornitoriTests
{
    [Theory]
    [InlineData("Inviato")]
    [InlineData("Parziale")]
    [InlineData("Ricevuto")]
    [InlineData("Annullato")]
    public async Task SalvaTestata_OrdineNonInBozza_NonInvocaScritture(string stato)
    {
        var pagina = new ModificaModel(new RepositoryNonBozza(stato), null!, NullLogger<ModificaModel>.Instance);
        var risultato = await pagina.OnPostAsync(7, CancellationToken.None);
        Assert.IsType<RedirectToPageResult>(risultato);
    }

    [Theory]
    [InlineData("Inviato")]
    [InlineData("Parziale")]
    [InlineData("Ricevuto")]
    [InlineData("Annullato")]
    public async Task SalvaRiga_OrdineNonInBozza_NonInvocaScritture(string stato)
    {
        var pagina = new RigaModel(new RepositoryNonBozza(stato), null!, NullLogger<RigaModel>.Instance);
        var risultato = await pagina.OnPostAsync(7, null, CancellationToken.None);
        Assert.IsType<RedirectToPageResult>(risultato);
    }

    [Theory]
    [InlineData("it-IT")]
    [InlineData("en-US")]
    public void QuantitaFrazionaria_ValidaConLeCultureSupportate(string cultura)
    {
        var precedente = CultureInfo.CurrentCulture;
        try
        {
            CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo(cultura);
            var modello = new OrdineFornitoreRigaFormModel
            {
                Descrizione = "Materiale di prova", Quantita = 0.0001m, PrezzoUnitario = 2.45m
            };
            var errori = new List<ValidationResult>();
            Assert.True(Validator.TryValidateObject(modello, new ValidationContext(modello), errori, true));
        }
        finally
        {
            CultureInfo.CurrentCulture = precedente;
        }
    }

    private sealed class RepositoryNonBozza(string stato) : IOrdineFornitoreRepository
    {
        public Task<OrdineFornitoreDettaglio?> GetDettaglioAsync(int id, CancellationToken cancellationToken = default) =>
            Task.FromResult<OrdineFornitoreDettaglio?>(new() { IdOrdineFornitore = id, Stato = stato });
        public Task<IReadOnlyList<OrdineFornitoreDettaglio>> GetElencoAsync(OrdineFornitoreFiltro filtro, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<IReadOnlyList<OrdineFornitoreRiga>> GetRigheAsync(int idOrdine, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<IReadOnlyList<OrdineFornitoreDipendenza>> GetDipendenzeAsync(int idOrdine, int? idRiga = null, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Accesso inatteso.");
        public Task<int> SalvaAsync(int? id, OrdineFornitoreSalvataggio modello, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task<int> SalvaRigaAsync(int idOrdine, int? idRiga, OrdineFornitoreRigaSalvataggio modello, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task EliminaAsync(int id, byte[] versione, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
        public Task EliminaRigaAsync(int idOrdine, int idRiga, byte[] versioneOrdine, byte[] versioneRiga, string utente, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("Scrittura inattesa.");
    }
}

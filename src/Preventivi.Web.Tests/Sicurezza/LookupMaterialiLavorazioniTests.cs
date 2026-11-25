using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Preventivi.Core.Anagrafiche;
using Preventivi.Core.Preventivi;
using Preventivi.Web.Pages.Preventivi.Riga;
using Xunit;
using DM = Preventivi.Core.Preventivi.DistintaMaterialeLookupItem;
using DL = Preventivi.Core.Preventivi.DistintaLavorazioneLookupItem;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class LookupMaterialiLavorazioniTests
{
    [Theory]
    [InlineData("Distinta")]
    [InlineData("Anagrafica")]
    public async Task Apertura_ProponeValoriDellaSorgente(string origine)
    {
        var s = new Stato(); var m = Materiali(s, origine); var l = Lavorazioni(s, origine);
        Assert.IsType<PageResult>(await m.OnGetAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<PageResult>(await l.OnGetAsync("nuovo", 1, 2, 3, null, default));
        Assert.Equal("Carta", m.NuovoMateriale.DescrizioneMateriale);
        Assert.Equal(5m, m.NuovoMateriale.CostoUnitario);
        Assert.Equal(origine == "Distinta" ? 4m : 1m, m.NuovoMateriale.Quantita);
        Assert.Equal("Stampa", l.NuovaLavorazione.DescrizioneLavorazione);
        Assert.Equal(30m, l.NuovaLavorazione.CostoOrario);
        Assert.Equal(2m, l.NuovaLavorazione.TempoSetupMin);
        Assert.Equal(8, m.NuovoMateriale.IdFornitoreSuggerito);
        Assert.Equal(0, s.Salvataggi);
    }

    [Theory]
    [InlineData("Distinta", false)] [InlineData("Anagrafica", false)]
    [InlineData("Distinta", true)] [InlineData("Anagrafica", true)]
    public async Task Salva_ConservaValoriDigitatiEVerificaIdentita(string origine, bool zero)
    {
        var s = new Stato(); var m = Materiali(s, origine); var l = Lavorazioni(s, origine);
        var valore = zero ? 0m : 12.3456m;
        m.NuovoMateriale = new() { IdMateriale = 999, IdRigaCompPrev = 999, IdNodoDistinta = 999,
            DescrizioneMateriale = "Falsa", UM = "Falsa", Quantita = valore, CostoUnitario = valore,
            IdFornitoreSuggerito = 9, DaAcquistare = false };
        l.NuovaLavorazione = new() { IdLavorazione = 999, DescrizioneLavorazione = "Falsa",
            Sequenza = 77, TempoSetupMin = valore, TempoPezzoMin = valore, Quantita = valore,
            CostoOrario = valore, CostoFisso = valore, IdFornitoreSuggerito = 9, DaAcquistareEsterno = false };
        Assert.IsType<RedirectToPageResult>(await m.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<RedirectToPageResult>(await l.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.Equal(valore, s.Materiale!.Quantita); Assert.Equal(valore, s.Materiale.CostoUnitario);
        Assert.Equal(5, s.Materiale.IdMateriale); Assert.Equal(3, s.Materiale.IdRigaCompPrev);
        Assert.Equal(4, s.Materiale.IdNodoDistinta); Assert.Equal("PZ", s.Materiale.UM);
        Assert.Equal("Carta", s.Materiale.DescrizioneMateriale); Assert.False(s.Materiale.DaAcquistare);
        Assert.Equal(9, s.Materiale.IdFornitoreSuggerito);
        Assert.Equal(77, s.Lavorazione!.Sequenza); Assert.Equal(valore, s.Lavorazione.TempoSetupMin);
        Assert.Equal(valore, s.Lavorazione.TempoPezzoMin); Assert.Equal(valore, s.Lavorazione.Quantita);
        Assert.Equal(valore, s.Lavorazione.CostoOrario); Assert.Equal(valore, s.Lavorazione.CostoFisso);
        Assert.Equal(6, s.Lavorazione.IdLavorazione); Assert.Equal("Stampa", s.Lavorazione.DescrizioneLavorazione);
        Assert.False(s.Lavorazione.DaAcquistareEsterno); Assert.Equal(9, s.Lavorazione.IdFornitoreSuggerito);
    }

    [Theory]
    [InlineData("Distinta")] [InlineData("Anagrafica")]
    public async Task ErroreBinding_ConservaValoriSelezioniETestoNonNumerico(string origine)
    {
        var s = new Stato { RicercaVuota = true }; var m = Materiali(s, origine); var l = Lavorazioni(s, origine);
        m.NuovoMateriale.Quantita = 27; m.NuovoMateriale.IdFornitoreSuggerito = 9;
        m.ModelState.SetModelValue("NuovoMateriale.CostoUnitario", "abc", "abc");
        m.ModelState.AddModelError("NuovoMateriale.CostoUnitario", "Numero non valido");
        l.NuovaLavorazione.Quantita = 28; l.NuovaLavorazione.Sequenza = null;
        l.ModelState.AddModelError("NuovaLavorazione.CostoOrario", "Numero non valido");
        Assert.IsType<PageResult>(await m.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<PageResult>(await l.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.Equal(27m, m.NuovoMateriale.Quantita); Assert.Equal(9, m.NuovoMateriale.IdFornitoreSuggerito);
        Assert.Equal("abc", m.ModelState["NuovoMateriale.CostoUnitario"]!.AttemptedValue);
        Assert.Equal(28m, l.NuovaLavorazione.Quantita); Assert.Null(l.NuovaLavorazione.Sequenza);
        Assert.Equal(origine, m.Origine);
        if (origine == "Anagrafica") { Assert.Single(m.MaterialiAnagrafica); Assert.Single(l.LavorazioniAnagrafica); }
        Assert.Equal(0, s.Salvataggi);
    }

    [Theory]
    [InlineData("Distinta", false)] [InlineData("Distinta", true)] [InlineData("Anagrafica", true)]
    public async Task Nuovo_NegaAltroNodoOAnagraficaDisattivata(string origine, bool disattivata)
    {
        var s = new Stato { Disattivata = disattivata, Nodo = disattivata ? 4 : 999 };
        var m = Materiali(s, origine); var l = Lavorazioni(s, origine);
        Assert.IsType<PageResult>(await m.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<PageResult>(await l.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.False(m.ModelState.IsValid); Assert.False(l.ModelState.IsValid); Assert.Equal(0, s.Salvataggi);
    }

    [Theory]
    [InlineData("Libero")] [InlineData("Distinta")] [InlineData("Anagrafica")]
    public async Task Nuovo_NegaFornitoreNonDisponibile(string origine)
    {
        var s = new Stato(); var m = Materiali(s, origine); var l = Lavorazioni(s, origine);
        m.NuovoMateriale.DescrizioneMateriale = "Libero"; m.NuovoMateriale.IdFornitoreSuggerito = 80;
        l.NuovaLavorazione.DescrizioneLavorazione = "Libera"; l.NuovaLavorazione.IdFornitoreSuggerito = 80;
        Assert.IsType<PageResult>(await m.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<PageResult>(await l.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.Equal(0, s.Salvataggi);
    }

    [Fact]
    public async Task Libero_NonAccettaIdentitaAnagraficaNascosta()
    {
        var s = new Stato(); var m = Materiali(s, "Libero"); var l = Lavorazioni(s, "Libero");
        m.NuovoMateriale.IdMateriale = 999; m.NuovoMateriale.DescrizioneMateriale = "Libero";
        l.NuovaLavorazione.IdLavorazione = 999; l.NuovaLavorazione.DescrizioneLavorazione = "Libera";
        Assert.IsType<RedirectToPageResult>(await m.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.IsType<RedirectToPageResult>(await l.OnPostAsync("nuovo", 1, 2, 3, null, default));
        Assert.Null(s.Materiale!.IdMateriale); Assert.Null(s.Lavorazione!.IdLavorazione);
    }

    [Theory]
    [InlineData(80, true)] [InlineData(9, true)] [InlineData(null, true)]
    [InlineData(81, false)] [InlineData(0, false)]
    public async Task Modifica_ConservaSoloIlFornitoreStoricoGiaAssociato(int? fornitore, bool valido)
    {
        var s = new Stato();
        var m = new MaterialeModificaModel(Repo(s), Anagrafiche(s));
        var l = new LavorazioneModificaModel(Repo(s), Anagrafiche(s));
        Assert.IsType<PageResult>(await m.OnGetAsync(1, 2, 3, 10, default));
        Assert.IsType<PageResult>(await l.OnGetAsync(1, 2, 3, 11, default));
        Assert.Equal(80, m.Dati.IdFornitoreSuggerito);
        Assert.Contains(m.Fornitori, x => x.IdFornitore == 80 && !x.Attivo);
        m.Dati.IdFornitoreSuggerito = fornitore; l.Dati.IdFornitoreSuggerito = fornitore;
        var rm = await m.OnPostAsync(1, 2, 3, 10, default); var rl = await l.OnPostAsync(1, 2, 3, 11, default);
        if (valido) { Assert.IsType<RedirectToPageResult>(rm); Assert.IsType<RedirectToPageResult>(rl); Assert.Equal(2, s.Salvataggi); }
        else { Assert.IsType<PageResult>(rm); Assert.IsType<PageResult>(rl); Assert.Equal(0, s.Salvataggi); Assert.Equal(fornitore, m.Dati.IdFornitoreSuggerito); }
    }

    [Fact]
    public async Task ContestoErrato_NonSalva()
    {
        var s = new Stato();
        Assert.IsType<NotFoundResult>(await Materiali(s, "Libero").OnPostAsync("nuovo", 99, 2, 3, null, default));
        Assert.IsType<NotFoundResult>(await Lavorazioni(s, "Libero").OnPostAsync("nuovo", 99, 2, 3, null, default));
        Assert.Equal(0, s.Salvataggi);
    }

    private static MaterialiModel Materiali(Stato s, string origine) => new(Repo(s), null!, null!, Anagrafiche(s))
        { Origine = origine, IdMaterialeSelezionato = 5, IdDistintaMaterialeSelezionato = 15 };
    private static LavorazioniModel Lavorazioni(Stato s, string origine) => new(Repo(s), null!, null!, Anagrafiche(s))
        { Origine = origine, IdLavorazioneSelezionata = 6, IdDistintaLavorazioneSelezionata = 16 };
    private static IPreventivoRepository Repo(Stato s) => Proxy<IPreventivoRepository>(s);
    private static IAnagraficheProduttiveRepository Anagrafiche(Stato s) => Proxy<IAnagraficheProduttiveRepository>(s);
    private static T Proxy<T>(Stato s) where T : class
    { var p = DispatchProxy.Create<T, RepositoryProxy>(); ((RepositoryProxy)(object)p).Stato = s; return p; }
    public sealed class Stato
    {
        public bool Disattivata; public bool RicercaVuota; public int Nodo = 4; public int Salvataggi;
        public PreventivoRigaMaterialeCreateModel? Materiale; public PreventivoRigaLavorazioneCreateModel? Lavorazione;
    }
    public class RepositoryProxy : DispatchProxy
    {
        public Stato Stato = null!;
        protected override object? Invoke(MethodInfo? method, object?[]? args)
        {
            var m = new MaterialeLookupItem { IdMateriale = 5, Descrizione = "Carta", UM = "PZ", CostoUnitario = 5, GestitoAAcquisto = true, IdFornitorePredefinito = 8 };
            var l = new LavorazioneLookupItem { IdLavorazione = 6, Descrizione = "Stampa", CostoOrarioStandard = 30, TempoSetupMinDefault = 2, AcquistabileEsterna = true, IdFornitorePredefinito = 8 };
            switch (method!.Name)
            {
                case "GetDettaglioAsync": return Task.FromResult<PreventivoDettaglio?>(new() { IdPreventivo = 1 });
                case "GetRigaAsync": return Task.FromResult<PreventivoRigaDettaglio?>(new() { IdPreventivo = 1, IdRigaPreventivo = 2 });
                case "GetComponenteAsync": return Task.FromResult<PreventivoRigaComponenteItem?>(new() { IdRigaPreventivo = 2, IdRigaCompPrev = 3, IdNodoDistinta = 4 });
                case "GetMaterialiAsync": return Task.FromResult<IReadOnlyList<MaterialeListItem>>(Stato.Disattivata ? [] : [new() { IdMateriale = 5, Attivo = true }]);
                case "GetLavorazioniAsync": return Task.FromResult<IReadOnlyList<LavorazioneListItem>>(Stato.Disattivata ? [] : [new() { IdLavorazione = 6, Attiva = true }]);
                case "GetMaterialiDistintaAsync": return Task.FromResult<IReadOnlyList<DM>>([new() { IdDistintaMateriale = 15, IdNodoDistinta = Stato.Nodo, IdMateriale = 5, DescrizioneMateriale = "Carta", UM = "PZ", Quantita = 4, CostoUnitario = 5, DaAcquistare = true, IdFornitoreSuggerito = 8 }]);
                case "GetLavorazioniDistintaAsync": return Task.FromResult<IReadOnlyList<DL>>([new() { IdDistintaLavorazione = 16, IdNodoDistinta = Stato.Nodo, IdLavorazione = 6, DescrizioneLavorazione = "Stampa", Sequenza = 20, TempoSetupMin = 2, CostoOrario = 30, DaAcquistareEsterno = true, IdFornitoreSuggerito = 8 }]);
                case "CercaMaterialiAsync": return Task.FromResult<IReadOnlyList<MaterialeLookupItem>>(Stato.RicercaVuota ? [] : [m]);
                case "CercaLavorazioniAsync": return Task.FromResult<IReadOnlyList<LavorazioneLookupItem>>(Stato.RicercaVuota ? [] : [l]);
                case "GetMaterialeAnagraficaAsync": return Task.FromResult<MaterialeLookupItem?>(m);
                case "GetLavorazioneAnagraficaAsync": return Task.FromResult<LavorazioneLookupItem?>(l);
                case "GetFornitoriAsync" when method.DeclaringType == typeof(IPreventivoRepository): return Task.FromResult<IReadOnlyList<FornitoreLookupItem>>([new() { IdFornitore = 8 }, new() { IdFornitore = 9 }]);
                case "GetFornitoriAsync": Assert.Equal(80, args![0]); return Task.FromResult<IReadOnlyList<FornitoreAnagraficaLookupItem>>([new() { IdFornitore = 9, Attivo = true }, new() { IdFornitore = 80, Attivo = false }]);
                case "GetMaterialeAsync": return Task.FromResult<PreventivoRigaMaterialeItem?>(new() { IdRigaMatPrev = 10, IdRigaPreventivo = 2, IdRigaCompPrev = 3, DescrizioneMateriale = "Storico", IdFornitoreSuggerito = 80 });
                case "GetLavorazioneAsync": return Task.FromResult<PreventivoRigaLavorazioneItem?>(new() { IdRigaLavPrev = 11, IdRigaPreventivo = 2, IdRigaCompPrev = 3, DescrizioneLavorazione = "Storica", IdFornitoreSuggerito = 80 });
                case "CreaMaterialeAsync": Stato.Materiale = (PreventivoRigaMaterialeCreateModel)args![0]!; Stato.Salvataggi++; return Task.FromResult(10);
                case "CreaLavorazioneAsync": Stato.Lavorazione = (PreventivoRigaLavorazioneCreateModel)args![0]!; Stato.Salvataggi++; return Task.FromResult(11);
                case "AggiornaMaterialeAsync": case "AggiornaLavorazioneAsync": Stato.Salvataggi++; return Task.CompletedTask;
                default: throw new InvalidOperationException(method.Name);
            }
        }
    }
}

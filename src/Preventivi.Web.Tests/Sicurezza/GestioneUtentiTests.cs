using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Preventivi.Core.Sicurezza;
using Preventivi.Web.Sicurezza;
using Xunit;
using P=Preventivi.Web.Pages.Amministrazione.Utenti;

namespace Preventivi.Web.Tests.Sicurezza;

public sealed class GestioneUtentiTests
{
    private static readonly Guid Stamp=Guid.Parse("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
    private static readonly AmministratoreOperante Admin=new(1,Stamp);
    [Theory]
    [InlineData("elenco")]
    [InlineData("dettaglio")]
    [InlineData("modifica-get")]
    [InlineData("modifica-post")]
    [InlineData("password-get")]
    [InlineData("password-post")]
    [InlineData("stato-get")]
    [InlineData("stato-post")]
    public async Task Operatore_NegaTutteLePagineAncheConRichiesteDirette(string pagina)
    {
        var repo=new Repository(); var service=Servizio(repo);
        PageModel modello; Func<Task<IActionResult>> azione;
        switch(pagina)
        {
            case "elenco":var elenco=new P.IndexModel(repo);modello=elenco;azione=()=>elenco.OnGetAsync(default);break;
            case "dettaglio":var dettaglio=new P.DettaglioModel(repo);modello=dettaglio;azione=()=>dettaglio.OnGetAsync(2,default);break;
            case "modifica-get":case "modifica-post":var modifica=new P.ModificaModel(repo,service);modello=modifica;azione=()=>pagina.EndsWith("get")?modifica.OnGetAsync(2,default):modifica.OnPostAsync(2,default);break;
            case "password-get":case "password-post":var password=new P.PasswordModel(repo,service);modello=password;azione=()=>pagina.EndsWith("get")?password.OnGetAsync(2,default):password.OnPostAsync(2,default);break;
            default:var stato=new P.StatoModel(repo,service);modello=stato;azione=()=>pagina.EndsWith("get")?stato.OnGetAsync(2,default):stato.OnPostAsync(2,default);break;
        }
        modello.PageContext=Contesto("OPERATORE");
        Assert.IsType<ForbidResult>(await azione()); Assert.Equal(0,repo.Chiamate);
    }

    [Fact]
    public void Attore_SenzaAutenticazioneOSessione_NonAccettaAdmin()
    {
        Assert.Null(GestioneUtentiApplicationService.Attore(new ClaimsPrincipal(new ClaimsIdentity())));
        var vecchio=ClaimsApplicazioneFactory.Crea(Utente(stamp:Guid.Empty));
        Assert.Null(GestioneUtentiApplicationService.Attore(vecchio));
    }

    [Theory]
    [InlineData("valida",true)]
    [InlineData("disattivato",false)]
    [InlineData("reset",false)]
    [InlineData("identita",false)]
    [InlineData("senza-password",false)]
    [InlineData("vecchio-cookie",false)]
    public void Sessione_VerificaIdentitaStatoEVersione(string caso,bool attesa)
    {
        var principal=ClaimsApplicazioneFactory.Crea(Utente(stamp:caso=="vecchio-cookie"?Guid.Empty:Stamp));
        var utente=Utente(attivo:caso!="disattivato",stamp:caso=="reset"?Guid.NewGuid():Stamp,
            id:caso=="identita"?99:1,hash:caso=="senza-password"?null:"hash");
        Assert.Equal(attesa,SessioneApplicazioneEvents.SessioneValida(principal,utente));
        Assert.DoesNotContain(principal.Claims,c=>c.Value=="hash");
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Cookie_RevocatoODatabaseNonDisponibile_RifiutaEScollega(bool databaseNonDisponibile)
    {
        var auth=new AutenticazioneFinta();
        var context=CookieContext(auth);
        var repository=new AccessoRepository(databaseNonDisponibile?Utente():null) { Errore=databaseNonDisponibile };
        await new SessioneApplicazioneEvents(repository,NullLogger<SessioneApplicazioneEvents>.Instance).ValidatePrincipal(context);
        Assert.Null(context.Principal); Assert.Equal(1,auth.Uscite);
    }

    [Fact]
    public async Task Cookie_PermessiAggiornati_SostituisceIlPrincipalPrimaDellePolicy()
    {
        var auth=new AutenticazioneFinta(); var context=CookieContext(auth);
        var fresco=Utente(ruoli:["OPERATORE"]);
        await new SessioneApplicazioneEvents(new AccessoRepository(fresco),NullLogger<SessioneApplicazioneEvents>.Instance).ValidatePrincipal(context);
        Assert.False(context.Principal!.IsInRole("ADMIN")); Assert.True(context.ShouldRenew); Assert.Equal(0,auth.Uscite);
    }

    [Fact]
    public async Task Creazione_InviaUnHashVerificabileSenzaSalvareLaPasswordInChiaro()
    {
        var repo=new Repository(); const string password="Password-di-test-019";
        var dati=new UtenteSalvataggio { Username="  operatore  ",Ruoli=[2] };
        await Servizio(repo).SalvaAsync(Admin,null,dati,password);
        Assert.Equal("operatore",dati.Username); Assert.NotEqual(password,repo.Hash);
        Assert.NotEqual(PasswordVerificationResult.Failed,new PasswordHasher<UtenteAccesso>().VerifyHashedPassword(new() { Username="operatore" },repo.Hash!,password));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("corta")]
    [InlineData("            ")]
    public async Task Creazione_PasswordNonValida_NonScrive(string? password)
    {
        var repo=new Repository();
        await Assert.ThrowsAsync<ArgumentException>(()=>Servizio(repo).SalvaAsync(Admin,null,new() { Username="prova",Ruoli=[2] },password));
        Assert.Equal(0,repo.Scritture);
    }

    [Fact]
    public async Task Modifica_NonTrasformaUnCampoPasswordInUnResetImplicito()
    {
        var repo=new Repository();
        await Servizio(repo).SalvaAsync(Admin,2,new() { Username="prova",Ruoli=[2],VersioneRiga=new byte[8] },"valore-iniettato");
        Assert.Null(repo.Hash); Assert.Equal(1,repo.Scritture);
    }

    [Fact]
    public async Task Servizio_BloccaDisattivazioneDelProprioAccount()
    {
        var repo=new Repository();
        await Assert.ThrowsAsync<ArgumentException>(()=>Servizio(repo).SalvaAsync(Admin,1,new() { Username="admin",Attivo=false,Ruoli=[1] },null));
        Assert.Equal(0,repo.Scritture);
    }

    [Fact]
    public async Task Servizio_SenzaRuoli_NonCreaUtente()
    {
        var repo=new Repository();
        await Assert.ThrowsAsync<ArgumentException>(()=>Servizio(repo).SalvaAsync(Admin,null,new() { Username="test",Ruoli=[] },"Password-di-test-019"));
        Assert.Equal(0,repo.Scritture);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Servizio_VersioneNonValida_NonModificaENonReimposta(bool reset)
    {
        var repo=new Repository(); var servizio=Servizio(repo);
        await Assert.ThrowsAsync<ArgumentException>(()=>reset
            ? servizio.ReimpostaAsync(Admin,new() { IdUtente=2,Username="test" },[],"Password-di-test-019")
            : servizio.SalvaAsync(Admin,2,new() { Username="test",Ruoli=[2] },null));
        Assert.Equal(0,repo.Scritture);
    }

    [Fact]
    public async Task PaginaStato_RichiedeConferma()
    {
        var repo=new Repository(); var pagina=new P.StatoModel(repo,Servizio(repo))
        { PageContext=Contesto("ADMIN"),Versione=Convert.ToBase64String(new byte[8]),Conferma=false };
        Assert.IsType<PageResult>(await pagina.OnPostAsync(2,default)); Assert.Equal(0,repo.Scritture);
    }

    [Fact]
    public async Task Creazione_ConfermaErrata_NonRiproponeLePasswordNelForm()
    {
        var repo=new Repository(); var pagina=new P.ModificaModel(repo,Servizio(repo))
        { PageContext=Contesto("ADMIN"),Password="Password-di-test-019",ConfermaPassword="diversa",Dati=new() { Username="test",Ruoli=[2] } };
        Assert.IsType<PageResult>(await pagina.OnPostAsync(null,default));
        Assert.Null(pagina.Password); Assert.Null(pagina.ConfermaPassword); Assert.Equal(0,repo.Scritture);
        Assert.False(pagina.ModelState.IsValid);
    }

    [Fact]
    public async Task ResetPassword_UsaHashEVersioneRicevuta()
    {
        var repo=new Repository(); var versione=new byte[] { 1,2,3,4,5,6,7,8 };
        await Servizio(repo).ReimpostaAsync(Admin,new() { IdUtente=2,Username="prova" },versione,"Password-di-test-019");
        Assert.Equal(1,repo.Scritture); Assert.Equal(versione,repo.Versione);
        Assert.NotEqual("Password-di-test-019",repo.Hash);
    }

    private static GestioneUtentiApplicationService Servizio(Repository repo)=>new(repo,new PasswordHasher<UtenteAccesso>());
    private static UtenteAccesso Utente(bool attivo=true,Guid? stamp=null,int id=1,string? hash="hash",string[]? ruoli=null)=>new()
    { IdUtente=id,Username="admin",Attivo=attivo,VersioneSessione=stamp??Stamp,PasswordHash=hash,Ruoli=ruoli??["ADMIN"] };
    private static PageContext Contesto(string ruolo)=>new() { HttpContext=new DefaultHttpContext { User=ClaimsApplicazioneFactory.Crea(Utente(ruoli:[ruolo])) } };
    private static CookieValidatePrincipalContext CookieContext(AutenticazioneFinta auth)
    {
        var http=new DefaultHttpContext { RequestServices=new ServiceCollection().AddSingleton<IAuthenticationService>(auth).BuildServiceProvider() };
        var principal=ClaimsApplicazioneFactory.Crea(Utente());
        var scheme=new AuthenticationScheme(CookieAuthenticationDefaults.AuthenticationScheme,null,typeof(CookieAuthenticationHandler));
        return new(http,scheme,new CookieAuthenticationOptions(),new AuthenticationTicket(principal,scheme.Name));
    }
    private sealed class AccessoRepository(UtenteAccesso? utente):IUtenteAccessoRepository
    {
        public bool Errore;
        public Task<UtenteAccesso?> GetByUsernameAsync(string username,CancellationToken cancellationToken=default)=>Errore?throw new InvalidOperationException():Task.FromResult(utente);
        public Task<bool> InizializzaPasswordAdminAsync(string username,string passwordHash,CancellationToken cancellationToken=default)=>throw new InvalidOperationException();
    }
    private sealed class AutenticazioneFinta:IAuthenticationService
    {
        public int Uscite;
        public Task SignOutAsync(HttpContext context,string? scheme,AuthenticationProperties? properties) { Uscite++; return Task.CompletedTask; }
        public Task<AuthenticateResult> AuthenticateAsync(HttpContext context,string? scheme)=>throw new InvalidOperationException();
        public Task ChallengeAsync(HttpContext context,string? scheme,AuthenticationProperties? properties)=>throw new InvalidOperationException();
        public Task ForbidAsync(HttpContext context,string? scheme,AuthenticationProperties? properties)=>throw new InvalidOperationException();
        public Task SignInAsync(HttpContext context,string? scheme,ClaimsPrincipal principal,AuthenticationProperties? properties)=>throw new InvalidOperationException();
    }
    private sealed class Repository:IGestioneUtentiRepository
    {
        public int Chiamate,Scritture; public string? Hash; public byte[]? Versione;
        public Task<IReadOnlyList<UtenteGestione>> GetElencoAsync(AmministratoreOperante attore,string? ricerca,bool? attivo,CancellationToken cancellationToken=default)
        { Chiamate++;return Task.FromResult<IReadOnlyList<UtenteGestione>>([]); }
        public Task<UtenteGestione?> GetDettaglioAsync(AmministratoreOperante attore,int id,CancellationToken cancellationToken=default)
        { Chiamate++;return Task.FromResult<UtenteGestione?>(new() { IdUtente=id,Username="prova",Attivo=true,RuoliJson="[2]",VersioneRiga=new byte[8] }); }
        public Task<IReadOnlyList<RuoloGestione>> GetRuoliAsync(AmministratoreOperante attore,CancellationToken cancellationToken=default)
        { Chiamate++;return Task.FromResult<IReadOnlyList<RuoloGestione>>([new() { IdRuolo=2,CodiceRuolo="OPERATORE",Attivo=true }]); }
        public Task<IReadOnlyList<UtenteAudit>> GetAuditAsync(AmministratoreOperante attore,int id,CancellationToken cancellationToken=default)
        { Chiamate++;return Task.FromResult<IReadOnlyList<UtenteAudit>>([]); }
        public Task<int> SalvaAsync(AmministratoreOperante attore,int? id,UtenteSalvataggio dati,string? passwordHash,CancellationToken cancellationToken=default)
        { Chiamate++;Scritture++;Hash=passwordHash;return Task.FromResult(id??2); }
        public Task ReimpostaPasswordAsync(AmministratoreOperante attore,int id,byte[] versione,string passwordHash,CancellationToken cancellationToken=default)
        { Chiamate++;Scritture++;Hash=passwordHash;Versione=versione;return Task.CompletedTask; }
    }
}

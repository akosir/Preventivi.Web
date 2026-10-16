using Microsoft.AspNetCore.Identity;
using Preventivi.Core.Sicurezza;

namespace Preventivi.Web.Sicurezza;

public sealed class AutenticazioneApplicazioneService
{
    private readonly IUtenteAccessoRepository _repository;
    private readonly IPasswordHasher<UtenteAccesso> _passwordHasher;
    private readonly string _hashFittizio;

    public AutenticazioneApplicazioneService(
        IUtenteAccessoRepository repository,
        IPasswordHasher<UtenteAccesso> passwordHasher)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
        var utenteFittizio = new UtenteAccesso { Username = "accesso-non-valido" };
        _hashFittizio = passwordHasher.HashPassword(utenteFittizio, Guid.NewGuid().ToString("N"));
    }

    public async Task<UtenteAccesso?> VerificaAsync(
        string username,
        string password,
        CancellationToken cancellationToken = default)
    {
        var utente = await _repository.GetByUsernameAsync(
            username.Trim(),
            cancellationToken);
        var utenteVerifica = utente ?? new UtenteAccesso { Username = username.Trim() };
        var hash = string.IsNullOrWhiteSpace(utente?.PasswordHash)
            ? _hashFittizio
            : utente.PasswordHash;
        var risultato = _passwordHasher.VerifyHashedPassword(
            utenteVerifica,
            hash,
            password);

        if (utente is null ||
            !utente.Attivo ||
            string.IsNullOrWhiteSpace(utente.PasswordHash) ||
            risultato == PasswordVerificationResult.Failed)
        {
            return null;
        }

        return utente;
    }
}

using Microsoft.AspNetCore.Identity;
using Preventivi.Core.Sicurezza;

namespace Preventivi.Web.Sicurezza;

public sealed class PasswordAdminInitializer
{
    private const int LunghezzaMinima = 12;

    private readonly IUtenteAccessoRepository _repository;
    private readonly IPasswordHasher<UtenteAccesso> _passwordHasher;

    public PasswordAdminInitializer(
        IUtenteAccessoRepository repository,
        IPasswordHasher<UtenteAccesso> passwordHasher)
    {
        _repository = repository;
        _passwordHasher = passwordHasher;
    }

    public async Task EseguiAsync(CancellationToken cancellationToken = default)
    {
        if (Console.IsInputRedirected)
        {
            throw new InvalidOperationException(
                "L'inizializzazione richiede una console interattiva.");
        }

        Console.Write("Username amministratore: ");
        var username = Console.ReadLine()?.Trim();

        if (string.IsNullOrWhiteSpace(username))
        {
            throw new InvalidOperationException("Username non specificato.");
        }

        var utente = await _repository.GetByUsernameAsync(username, cancellationToken);

        if (utente is null ||
            !utente.Ruoli.Contains(
                AutorizzazioneApplicazione.RuoloAdmin,
                StringComparer.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                "L'utente indicato non è un amministratore attivo.");
        }

        if (!string.IsNullOrWhiteSpace(utente.PasswordHash))
        {
            throw new InvalidOperationException(
                "La password dell'amministratore è già inizializzata.");
        }

        Console.Write("Nuova password: ");
        var password = LeggiPassword();
        Console.Write("Conferma password: ");
        var conferma = LeggiPassword();

        if (password.Length < LunghezzaMinima)
        {
            throw new InvalidOperationException(
                $"La password deve contenere almeno {LunghezzaMinima} caratteri.");
        }

        if (!string.Equals(password, conferma, StringComparison.Ordinal))
        {
            throw new InvalidOperationException("Le password non coincidono.");
        }

        var hash = _passwordHasher.HashPassword(utente, password);
        var aggiornata = await _repository.InizializzaPasswordAdminAsync(
            utente.Username,
            hash,
            cancellationToken);

        if (!aggiornata)
        {
            throw new InvalidOperationException(
                "La password non è stata inizializzata. Verificare lo stato dell'utente.");
        }

        Console.WriteLine("Password amministrativa inizializzata correttamente.");
    }

    private static string LeggiPassword()
    {
        var caratteri = new List<char>();

        while (true)
        {
            var tasto = Console.ReadKey(intercept: true);

            if (tasto.Key == ConsoleKey.Enter)
            {
                Console.WriteLine();
                return new string(caratteri.ToArray());
            }

            if (tasto.Key == ConsoleKey.Backspace)
            {
                if (caratteri.Count > 0)
                {
                    caratteri.RemoveAt(caratteri.Count - 1);
                }

                continue;
            }

            if (!char.IsControl(tasto.KeyChar))
            {
                caratteri.Add(tasto.KeyChar);
            }
        }
    }
}

using System.ComponentModel.DataAnnotations;
using System.Reflection;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace Preventivi.Web.UI;

public static class ValidazioneLunghezzeTesto
{
    // Ripetere il controllo dopo la ricostruzione dei dati non modificabili
    // provenienti dai lookup, anche quando il loro ModelState viene rimosso.
    public static void ValidaLunghezzeTesto(this ModelStateDictionary modelState, object modello, string prefisso)
    {
        foreach (var proprieta in modello.GetType().GetProperties())
        {
            var limite = proprieta.GetCustomAttribute<StringLengthAttribute>();
            if (limite is null || limite.IsValid(proprieta.GetValue(modello))) continue;
            var nome = string.IsNullOrEmpty(prefisso) ? proprieta.Name : $"{prefisso}.{proprieta.Name}";
            var messaggio = limite.FormatErrorMessage(proprieta.GetCustomAttribute<DisplayAttribute>()?.GetName() ?? proprieta.Name);
            if (!modelState.TryGetValue(nome, out var stato) || stato.Errors.All(x => x.ErrorMessage != messaggio))
                modelState.AddModelError(nome, messaggio);
        }
    }
}

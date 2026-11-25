using System.ComponentModel.DataAnnotations;

namespace Preventivi.Data.Comune;

public static class ParametriTestoSql
{
    public static void VerificaLunghezza(string? valore, int massimo, string campo)
    {
        if (valore is not null && valore.Length > massimo)
            throw new ValidationException($"Il campo {campo.TrimStart('@')} puo contenere al massimo {massimo} caratteri. Il testo non e stato salvato.");
    }
}

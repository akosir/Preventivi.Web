namespace Preventivi.Core.Preventivi.Eliminazione;

public sealed class PreventivoEliminazioneException : Exception
{
    public PreventivoEliminazioneException(
        string message,
        Exception innerException,
        bool eliminazioneCompletata = false)
        : base(message, innerException)
    {
        EliminazioneCompletata = eliminazioneCompletata;
    }

    public bool EliminazioneCompletata { get; }
}

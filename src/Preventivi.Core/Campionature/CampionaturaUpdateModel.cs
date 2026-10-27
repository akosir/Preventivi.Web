namespace Preventivi.Core.Campionature;

public sealed class CampionaturaUpdateModel : CampionaturaCreateModel
{
    public int IdCampionatura { get; set; }
    public byte[] VersioneRiga { get; set; } = [];
}

namespace Preventivi.Web.Components.PFWPageHeader;

public class PFWPageHeaderModel
{
    public string Title { get; set; } = string.Empty;

    public string? Subtitle { get; set; }

    public string? PrimaryActionText { get; set; }

    public string? PrimaryActionPage { get; set; }

    public string? SecondaryActionText { get; set; }

    public string? SecondaryActionPage { get; set; }
}
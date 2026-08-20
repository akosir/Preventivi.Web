namespace Preventivi.Web.ViewModels.Components;

public class PageHeaderViewModel
{
    public string Title { get; set; } = string.Empty;

    public string? Subtitle { get; set; }

    public string? PrimaryActionText { get; set; }

    public string? PrimaryActionPage { get; set; }
}
using Microsoft.AspNetCore.Mvc;

namespace Preventivi.Web.Components.PFWPageHeader;

public class PFWPageHeaderViewComponent : ViewComponent
{
    public IViewComponentResult Invoke(
        string title,
        string? subtitle = null,
        string? primaryActionText = null,
        string? primaryActionPage = null,
        string? secondaryActionText = null,
        string? secondaryActionPage = null)
    {
        var model = new PFWPageHeaderModel
        {
            Title = title,
            Subtitle = subtitle,
            PrimaryActionText = primaryActionText,
            PrimaryActionPage = primaryActionPage,
            SecondaryActionText = secondaryActionText,
            SecondaryActionPage = secondaryActionPage
        };

        return View(model);
    }
}

using Microsoft.AspNetCore.Mvc;

namespace Preventivi.Web.Components.PFWPanel;

public class PFWPanelViewComponent : ViewComponent
{
    public IViewComponentResult Invoke(
        string? title = null,
        string? subtitle = null,
        string? headerLinkText = null,
        string? headerLinkPage = null,
        bool autoHeight = false,
        string? cssClass = null)
    {
        var model = new PFWPanelModel
        {
            Title = title,
            Subtitle = subtitle,
            HeaderLinkText = headerLinkText,
            HeaderLinkPage = headerLinkPage,
            AutoHeight = autoHeight,
            CssClass = cssClass
        };

        return View(model);
    }
}
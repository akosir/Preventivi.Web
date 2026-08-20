using Microsoft.AspNetCore.Razor.TagHelpers;

namespace Preventivi.Web.TagHelpers;

[HtmlTargetElement("pfw-panel")]
public class PFWPanelTagHelper : TagHelper
{
    public string? Title { get; set; }

    public string? Subtitle { get; set; }

    public bool AutoHeight { get; set; } = true;

    public string? CssClass { get; set; }

    public override async Task ProcessAsync(
        TagHelperContext context,
        TagHelperOutput output)
    {
        output.TagName = "section";

        var classes = "pfw-panel";

        if (AutoHeight)
        {
            classes += " pfw-panel-auto";
        }

        if (!string.IsNullOrWhiteSpace(CssClass))
        {
            classes += " " + CssClass;
        }

        output.Attributes.SetAttribute("class", classes);

        var childContent = await output.GetChildContentAsync();

        var html = string.Empty;

        if (!string.IsNullOrWhiteSpace(Title) ||
            !string.IsNullOrWhiteSpace(Subtitle))
        {
            html += """
                    <div class="pfw-panel-header">
                        <div>
                    """;

            if (!string.IsNullOrWhiteSpace(Title))
            {
                html +=
                    $"<h2 class=\"pfw-panel-title\">{Title}</h2>";
            }

            if (!string.IsNullOrWhiteSpace(Subtitle))
            {
                html +=
                    $"<div class=\"pfw-panel-subtitle\">{Subtitle}</div>";
            }

            html += """
                        </div>
                    </div>
                    """;
        }

        html += childContent.GetContent();

        output.Content.SetHtmlContent(html);
    }
}
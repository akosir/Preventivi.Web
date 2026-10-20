using System.Globalization;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace Preventivi.Web.TagHelpers;

[HtmlTargetElement("input", Attributes = ForAttributeName)]
public sealed class PFWDecimalInputTagHelper : TagHelper
{
    private const string ForAttributeName = "asp-for";

    [HtmlAttributeName(ForAttributeName)]
    public ModelExpression For { get; set; } = default!;

    [HtmlAttributeNotBound]
    [ViewContext]
    public ViewContext ViewContext { get; set; } = default!;

    public override int Order => 1000;

    public override void Process(
        TagHelperContext context,
        TagHelperOutput output)
    {
        var modelType = Nullable.GetUnderlyingType(For.Metadata.ModelType)
                        ?? For.Metadata.ModelType;

        if (modelType != typeof(decimal) || IsHidden(output))
        {
            return;
        }

        output.Attributes.SetAttribute("type", "text");
        output.Attributes.SetAttribute("inputmode", "decimal");

        var fullName = ViewContext.ViewData.TemplateInfo
            .GetFullHtmlFieldName(For.Name);

        if (ViewContext.ViewData.ModelState.ContainsKey(fullName))
        {
            return;
        }

        if (For.Model is decimal value)
        {
            output.Attributes.SetAttribute(
                "value",
                value.ToString(CultureInfo.CurrentCulture));
        }
    }

    private static bool IsHidden(TagHelperOutput output)
    {
        return output.Attributes.TryGetAttribute("type", out var type) &&
               string.Equals(
                   type.Value?.ToString(),
                   "hidden",
                   StringComparison.OrdinalIgnoreCase);
    }
}

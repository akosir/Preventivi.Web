using System.Globalization;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace Preventivi.Web.UI.ModelBinding;

public sealed class FlexibleDecimalModelBinder : IModelBinder
{
    public Task BindModelAsync(ModelBindingContext bindingContext)
    {
        ArgumentNullException.ThrowIfNull(bindingContext);

        var valueResult = bindingContext.ValueProvider.GetValue(
            bindingContext.ModelName);

        if (valueResult == ValueProviderResult.None)
        {
            return Task.CompletedTask;
        }

        bindingContext.ModelState.SetModelValue(
            bindingContext.ModelName,
            valueResult);

        var value = valueResult.FirstValue;
        var isNullable = Nullable.GetUnderlyingType(
            bindingContext.ModelType) is not null;

        if (string.IsNullOrWhiteSpace(value))
        {
            if (isNullable)
            {
                bindingContext.Result = ModelBindingResult.Success(null);
            }

            return Task.CompletedTask;
        }

        if (FlexibleDecimalParser.TryParse(value, out var parsedValue))
        {
            bindingContext.Result = ModelBindingResult.Success(parsedValue);
            return Task.CompletedTask;
        }

        bindingContext.ModelState.TryAddModelError(
            bindingContext.ModelName,
            $"Il valore '{value}' non e un numero valido.");

        return Task.CompletedTask;
    }
}

public sealed class FlexibleDecimalModelBinderProvider : IModelBinderProvider
{
    private static readonly IModelBinder Binder =
        new FlexibleDecimalModelBinder();

    public IModelBinder? GetBinder(ModelBinderProviderContext context)
    {
        ArgumentNullException.ThrowIfNull(context);

        var modelType = Nullable.GetUnderlyingType(
                            context.Metadata.ModelType)
                        ?? context.Metadata.ModelType;

        return modelType == typeof(decimal) ? Binder : null;
    }
}

public static class FlexibleDecimalParser
{
    private const NumberStyles SupportedStyles =
        NumberStyles.AllowLeadingSign |
        NumberStyles.AllowDecimalPoint;

    public static bool TryParse(string value, out decimal result)
    {
        var normalized = value
            .Trim()
            .Replace(" ", string.Empty, StringComparison.Ordinal)
            .Replace("\u00a0", string.Empty, StringComparison.Ordinal);

        var commaIndex = normalized.LastIndexOf(',');
        var dotIndex = normalized.LastIndexOf('.');

        if (commaIndex >= 0 && dotIndex >= 0)
        {
            var decimalSeparator = commaIndex > dotIndex ? ',' : '.';
            var groupSeparator = decimalSeparator == ',' ? "." : ",";
            normalized = normalized.Replace(
                groupSeparator,
                string.Empty,
                StringComparison.Ordinal);

            if (decimalSeparator == ',')
            {
                normalized = normalized.Replace(',', '.');
            }
        }
        else if (commaIndex >= 0)
        {
            normalized = normalized.Replace(',', '.');
        }

        return decimal.TryParse(
            normalized,
            SupportedStyles,
            CultureInfo.InvariantCulture,
            out result);
    }
}

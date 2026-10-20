using Preventivi.Web.UI.ModelBinding;
using Xunit;

namespace Preventivi.Web.Tests.UI.ModelBinding;

public sealed class FlexibleDecimalParserTests
{
    [Theory]
    [InlineData("500,00", "500.00")]
    [InlineData("2.00", "2.00")]
    [InlineData("1.234,56", "1234.56")]
    [InlineData("1,234.56", "1234.56")]
    [InlineData("-0,25", "-0.25")]
    public void TryParse_AccettaFormatiItalianiEInvariant(
        string input,
        string expectedInvariant)
    {
        var parsed = FlexibleDecimalParser.TryParse(input, out var value);

        Assert.True(parsed);
        Assert.Equal(
            decimal.Parse(
                expectedInvariant,
                System.Globalization.CultureInfo.InvariantCulture),
            value);
    }

    [Theory]
    [InlineData("12,34,56")]
    [InlineData("abc")]
    [InlineData("1-2")]
    public void TryParse_RifiutaValoriNonNumerici(string input)
    {
        Assert.False(FlexibleDecimalParser.TryParse(input, out _));
    }
}

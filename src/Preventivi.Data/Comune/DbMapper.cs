using Microsoft.Data.SqlClient;
using System.Reflection;

namespace Preventivi.Data.Comune;

public static class DbMapper
{
    public static T Map<T>(SqlDataReader reader)
        where T : new()
    {
        var item = new T();

        var properties = typeof(T)
            .GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Where(p => p.CanWrite)
            .ToDictionary(
                p => p.Name,
                p => p,
                StringComparer.OrdinalIgnoreCase);

        for (var i = 0; i < reader.FieldCount; i++)
        {
            var columnName = reader.GetName(i);

            if (!properties.TryGetValue(columnName, out var property))
                continue;

            if (reader.IsDBNull(i))
                continue;

            var value = reader.GetValue(i);
            var targetType = Nullable.GetUnderlyingType(property.PropertyType)
                             ?? property.PropertyType;

            if (targetType == typeof(DateOnly))
            {
                var dateTime = Convert.ToDateTime(value);
                property.SetValue(item, DateOnly.FromDateTime(dateTime));
                continue;
            }

            if (targetType.IsEnum)
            {
                var enumValue = Enum.Parse(
                    targetType,
                    value.ToString()!,
                    ignoreCase: true);

                property.SetValue(item, enumValue);
                continue;
            }

            var converted = Convert.ChangeType(value, targetType);
            property.SetValue(item, converted);
        }

        return item;
    }
}
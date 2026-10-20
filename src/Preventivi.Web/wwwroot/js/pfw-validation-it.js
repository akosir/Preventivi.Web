(function ($) {
    "use strict";

    if (!$ || !$.validator) {
        return;
    }

    function parseDecimal(value) {
        var normalized = String(value)
            .trim()
            .replace(/[\s\u00a0]/g, "");
        var commaIndex = normalized.lastIndexOf(",");
        var dotIndex = normalized.lastIndexOf(".");

        if (commaIndex >= 0 && dotIndex >= 0) {
            var decimalSeparator = commaIndex > dotIndex ? "," : ".";
            var groupSeparator = decimalSeparator === "," ? "." : ",";
            normalized = normalized.split(groupSeparator).join("");

            if (decimalSeparator === ",") {
                normalized = normalized.replace(",", ".");
            }
        } else if (commaIndex >= 0) {
            normalized = normalized.replace(",", ".");
        }

        if (!/^[+-]?(?:\d+(?:\.\d+)?|\.\d+)$/.test(normalized)) {
            return NaN;
        }

        return Number(normalized);
    }

    $.validator.methods.number = function (value, element) {
        return this.optional(element) || Number.isFinite(parseDecimal(value));
    };

    $.validator.methods.min = function (value, element, parameter) {
        return this.optional(element) ||
            parseDecimal(value) >= parseDecimal(parameter);
    };

    $.validator.methods.max = function (value, element, parameter) {
        return this.optional(element) ||
            parseDecimal(value) <= parseDecimal(parameter);
    };

    $.validator.methods.range = function (value, element, parameters) {
        var parsedValue = parseDecimal(value);
        return this.optional(element) ||
            parsedValue >= parseDecimal(parameters[0]) &&
            parsedValue <= parseDecimal(parameters[1]);
    };
})(window.jQuery);

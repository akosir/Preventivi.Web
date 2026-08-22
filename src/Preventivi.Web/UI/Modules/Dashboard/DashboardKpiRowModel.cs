using Preventivi.Web.UI.KPI;

namespace Preventivi.Web.UI.Modules.Dashboard;

public sealed class DashboardKpiRowModel
{
    public IReadOnlyList<PFWKPIModel> Elementi { get; init; } = [];
}
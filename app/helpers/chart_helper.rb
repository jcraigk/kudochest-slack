module ChartHelper
  def column_chart_with_labels(name:, data:, profile:, id:)
    column_chart \
      [{ name:, data:, library: chartjs_library_options(profile) }],
      id:
  end

  def chartjs_library_options(profile)
    {
      datalabels: {
        color: profile.theme.dark? ? '#cccccc' : '#000000',
        align: 'top',
        anchor: 'end'
      }
    }
  end
end

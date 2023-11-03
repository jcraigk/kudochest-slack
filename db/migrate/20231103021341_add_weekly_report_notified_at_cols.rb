class AddWeeklyReportNotifiedAtCols < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :weekly_report_notified_at, :datetime
    add_column :profiles, :weekly_report_notified_at, :datetime

    add_index :teams, :weekly_report_notified_at
    add_index :profiles, :weekly_report_notified_at
  end
end

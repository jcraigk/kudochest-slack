class DataExportWorker
  include Sidekiq::Worker

  attr_reader :team_id, :email

  def perform(team_id, email)
    @team_id = team_id
    @email = email
    send_email_with_csv_attachment
  end

  private

  def send_email_with_csv_attachment
    AdminMailer.data_export(team, csv_str, email).deliver_later
  end

  def csv_str
    CSV.generate do |csv|
      csv << [ "ID", "Name", App.points_term.titleize ]
      team.profiles.active.order(display_name: :asc).each do |profile|
        csv << csv_row(profile)
      end
    end
  end

  def csv_row(profile)
    [
      profile.rid,
      profile.display_name,
      profile.points
    ]
  end

  def team
    @team ||= Team.find(team_id)
  end
end

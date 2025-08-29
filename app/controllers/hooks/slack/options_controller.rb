class Hooks::Slack::OptionsController < Hooks::Slack::BaseController
  def receiver
    render json: { options: }
  end

  private

  def options
    (
      profile_options +
      subteam_options +
      channel_keyword_option +
      channel_name_options +
      everyone_keyword_option +
      here_keyword_option
    ).sort_by { |opt| opt[:text][:text] }
  end

  def everyone_keyword_option
    [ generic_option("#{App.prof_prefix}everyone", "everyone") ]
  end

  def here_keyword_option
    [ generic_option("#{App.prof_prefix}here", "here") ]
  end

  def channel_keyword_option
    [ generic_option("#{App.prof_prefix}channel", "channel") ]
  end

  def profile_options
    Profile.joins(:team)
           .where("teams.rid" => team_rid)
           .where.not("profiles.rid" => profile_rid)
           .matching(user_input)
           .distinct
           .map do |profile|
      generic_option("#{App.prof_prefix}#{profile.display_name} (#{profile.real_name})", profile.rid)
    end
  end

  def channel_name_options
    Channel.joins(:team)
           .where("teams.rid" => team_rid)
           .matching(user_input)
           .distinct
           .map do |channel|
      generic_option("#{App.chan_prefix} #{channel.name}", channel.rid)
    end
  end

  def subteam_options
    Subteam.joins(:team)
           .where("teams.rid" => team_rid)
           .matching(user_input)
           .distinct
           .map do |subteam|
      generic_option("#{App.prof_prefix}#{subteam.handle} (#{subteam.name})", subteam.rid)
    end
  end

  def generic_option(text, value)
    {
      text: {
        type: :plain_text,
        text:
      },
      value:
    }
  end

  def user_input
    payload[:value].gsub(/[^0-9a-z\s]/i, "")
  end

  def profile_rid
    payload[:user][:id]
  end

  def team_rid
    payload[:team][:id]
  end

  def payload
    @payload ||= JSON.parse(params[:payload], symbolize_names: true)
  end
end

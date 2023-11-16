class TokenDisbursalService < Base::Service
  option :team

  def call
    return unless team.throttle_tips?

    Team.transaction { disburse_tokens }
  end

  private

  def disburse_tokens
    team.profiles.active.where(infinite_tokens: false).find_each do |profile|
      forfeited_tokens = apply_tokens(profile)
      notify_user(profile, forfeited_tokens)
    end
    team.update_next_tokens_at
  end

  def notify_user(profile, forfeited_tokens)
    return unless team.notify_tokens? && profile.allow_dm?
    send_direct_message(profile, forfeited_tokens)
  end

  def next_disbursal_text
    phrase = distance_of_time_in_words(Time.current, team.next_tokens_at)
    <<~TEXT.chomp
      The next disbursal of #{number_with_delimiter(team.token_quantity)} tokens will occur in #{phrase}.
    TEXT
  end

  def success_text(profile)
    <<~TEXT.chomp
      You received #{number_with_delimiter(quantity)} tokens, bringing your total to #{points_format(profile.tokens)}.
    TEXT
  end

  def forfeit_text
    <<~TEXT.chomp
      We tried to give you #{number_with_delimiter(quantity)} tokens, but you maxed out at #{number_with_delimiter(max)}.
    TEXT
  end

  def send_direct_message(profile, forfeited_tokens)
    "#{team.plat}::PostService".constantize.call \
      config: team.config,
      team_rid: team.rid,
      profile_rid: profile.rid,
      mode: :direct,
      text: message_content(profile, forfeited_tokens)
  end

  def message_content(profile, forfeited_tokens)
    base_text = forfeited_tokens.positive? ? forfeit_text : success_text(profile)
    [base_text, next_disbursal_text].join(' ')
  end

  def apply_tokens(profile)
    forfeited_tokens = [profile.tokens + quantity - max, 0].max
    profile.update!(tokens: profile.tokens + [(max - profile.tokens), quantity].min)
    forfeited_tokens
  end

  def max
    @max ||= team.token_max
  end

  def quantity
    @quantity ||= team.token_quantity
  end
end

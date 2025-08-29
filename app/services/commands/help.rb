class Commands::Help < Commands::Base
  def call
    ChatResponse.new(mode: :private, text:)
  end

  private

  def text
    <<~TEXT.chomp
      *#{giving_title}:*
        #{slack_giving_points}

      *Issuing commands:*
        * Type `/#{App.base_command} [keyword]` anywhere
        * Type `#{team.app_profile.link} [keyword]` where bot is present
        * Send direct message to #{team.app_profile.link}

      *Command keywords:*
        #{keyword_list}
        #{shop_keywords}

      #{footer}
    TEXT
  end

  def shop_keywords
    return unless team.enable_loot?
    <<~TEXT.chomp
      * `shop`  See a list of claimable rewards
        * `claim [item]`  Claim a shop item by name
    TEXT
  end

  def keyword_list
    str = "* `admin`  See app configuration\n"
    str += "  * `help`  You're looking at it!\n"
    str += "  * `levels`  See a chart mapping #{App.points_term} to levels\n" if team.enable_levels?
    # str += "  * `me`  See your current stats\n" # Commented: User can discover this for themselves
    str += "  * `preferences`  Update your preferences\n"
    str += "  * `report [#{App.prof_prefix}user] [number]`  #{report_str}\n"
    str += "  * `stats [#{App.prof_prefix}user]`  See your own or another user's stats\n"
    str += "  * `top [number]`  See the leaderboard; optionally give number of entries\n"
    str += "  * `topics`  See all topics\n" if team.enable_topics?
    str + "  * `undo`  Revoke #{App.points_term} you just gave"
  end

  def report_str
    "See recent activity for team or user; optionally give number of days"
  end

  def giving_title
    str = "Giving #{App.points_term.titleize}"
    str += " and #{App.jabs_term.titleize}" if team.enable_jabs?
    str
  end

  def giving_terms
    str = App.point_term
    str += "/#{App.jab_term}" if team.enable_jabs?
    str
  end

  def footer
    ":globe_with_meridians: <#{App.base_url}|Web portal>   :question: <#{App.help_url}|More help> "
  end

  def slack_giving_points
    str = slack_point_inlines
    str += slack_jab_inlines if team.enable_jabs?
    str += slack_emojis if team.enable_thumbsup? || team.enable_emoji?
    str
  end

  def slack_point_inlines
    "* Type `/#{App.base_command}` by itself for assistance " \
      "_(tip: use Tab key to navigate fields)_" \
      "\n  * Type `#{App.prof_prefix}[user]++`, `#{App.prof_prefix}[group]++`, " \
      "`#{App.chan_prefix}[channel]++`, `#{App.prof_prefix}channel++`, `#{App.prof_prefix}here++`, " \
      "or `#{App.prof_prefix}everyone++` _(tip: append a number like `++2`)_"
  end

  def slack_jab_inlines
    "\n  * Type `#{App.prof_prefix}[user]--`, `#{App.prof_prefix}[group]--`, " \
      "`#{App.chan_prefix}[channel]--`, `#{App.prof_prefix}channel--`, `#{App.prof_prefix}here--`, " \
      "or `#{App.prof_prefix}everyone--` _(tip: append a number like `--2`)_"
  end

  def slack_emojis # rubocop:disable Metrics/AbcSize
    str = slack_inline_point_emojis
    str += slack_inline_jab_emojis if team.enable_jabs?
    reaction_emojis = []
    reaction_emojis << (team.enable_thumbsup? ? ":+1:" : team.point_emoj)
    reaction_emojis << team.jab_emoj if team.enable_jabs?
    str += "\n  * React with #{reaction_emojis.join(' or ')} to give to the author of a message"
    str + "\n  * React to #{giving_terms} message with #{team.ditto_emoj} to support it"
  end

  def slack_inline_point_emojis
    emoji = team.enable_thumbsup? ? ":+1:" : team.point_emoj
    "\n  * Type `#{App.prof_prefix}[user]`#{emoji}, " \
      "`#{App.prof_prefix}[group]`#{emoji}, " \
      "`#{App.chan_prefix}[channel]`#{emoji}, " \
      "`#{App.prof_prefix}channel`#{emoji}, " \
      "`#{App.prof_prefix}here`#{emoji}, or " \
      "`#{App.prof_prefix}everyone`#{emoji} _(tip: try " \
      "#{emoji * 3})_"
  end

  def slack_inline_jab_emojis
    "\n  * Type `#{App.prof_prefix}[user]`#{team.jab_emoj}, " \
      "`#{App.prof_prefix}[group]`#{team.jab_emoj}, " \
      "`#{App.chan_prefix}[channel]`#{team.jab_emoj}, " \
      "`#{App.prof_prefix}channel`#{team.jab_emoj}, " \
      "`#{App.prof_prefix}here`#{team.jab_emoj}, or " \
      "`#{App.prof_prefix}everyone`#{team.jab_emoj} _(tip: try " \
      "#{team.jab_emoj * 3})_"
  end
end

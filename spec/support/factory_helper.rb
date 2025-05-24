module FactoryHelper
  def self.rid(platform, first_char = nil)
    case platform.to_sym
    when :slack then slack_rid(first_char)
    end
  end

  def self.slack_rid(first_char)
    chars = [ ('A'..'Z'), (0..9) ].map(&:to_a).flatten
    rid = (0...8).map { chars[rand(chars.length)] }.join
    first_char + rid
  end
end

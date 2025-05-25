module FactoryHelper
  def self.rid(first_char = nil)
    chars = [ ('A'..'Z'), (0..9) ].map(&:to_a).flatten
    rid = (0...8).map { chars[rand(chars.length)] }.join
    first_char + rid
  end
end

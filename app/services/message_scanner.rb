# Scan a message from the chat client to find triggrs that could result in Tip creation.
# Because this is called on every message sent from chat, it should be efficient.

class MessageScanner < Base::Service
  option :text
  option :regex

  def call
    matches_on_text
  end

  private

  def scan_results
    @scan_results ||= sanitized_text.scan(regex).map do |match|
      regex.names.map(&:to_sym).zip(match).to_h
    end || []
  end

  def matches_on_text # rubocop:disable Metrics/MethodLength
    scan_results.each_with_index.map do |match, idx|
      {
        rid: rid(match),
        prefix_quantity: prefix_quantity(match),
        inline_text: inline_text(match),
        inline_emoji: sanitized_emoji(match),
        suffix_quantity: suffix_quantity(match),
        topic_keyword: topic_keyword(match),
        note: note(idx)
      }.compact
    end
  end

  def topic_keyword(match)
    match[:topic_keywords].presence
  end

  def inline_text(match)
    match[:inlines].presence
  end

  # Override prefix_quantity with number of repeated inlines (++++ => 2)
  # Assumes inlines are 2 chars long
  def prefix_quantity(match)
    inline_count = (inline_text(match).to_s.length / 2.0).floor
    inline_count > 1 ? inline_count : quantity_or_nil(match[:prefix_quantity])
  end

  def suffix_quantity(match)
    quantity_or_nil(match[:suffix_quantity])
  end

  def rid(match)
    match[:entity_rid] || match[:group_keyword]
  end

  def quantity_or_nil(str)
    str.presence&.to_i
  end

  def sanitized_emoji(match)
    match[:emojis]&.gsub(/[^a-z_\-:]/, '')
  end

  def note(idx)
    NoteSanitizer.call(text: raw_note(idx))
  end

  # Note is all text between matches, defaulting to tail
  def raw_note(idx)
    tail = text.split(scan_results[idx][:match])[1]
    return tail if (next_match = scan_results[idx + 1]&.dig(:match)).nil?
    intermediate_note(tail, next_match) || tail_note
  end

  def intermediate_note(tail, next_match)
    tail&.split(next_match)&.first&.strip.presence
  end

  def tail_note
    @tail_note ||= text.split(scan_results[-1][:match])[1]&.strip
  end

  def sanitized_text
    text&.strip&.tr("\u00A0", ' ') || '' # `\u00A0` is unicode space (from Slack)
  end
end

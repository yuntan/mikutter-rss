# frozen_string_literal: true

require_relative 'fetch'
require_relative 'settings'

Plugin.create :rss do
  # === event handlers ===

  on_rss_appear_entries do |entries|
    Plugin.call :extract_receive_message, :rss_appear_entries, entries
  end

  on_userconfig_modify do |key|
    if key == :rss_sources
      Plugin.call :rss_init
      Plugin.call :rss_fetch
    end
  end

  on_rss_init do
    filter_extract_datasources do |dss|
      dss = dss.merge rss: 'All of received RSS entries'
      UserConfig[:rss_sources].each_with_index do |url, i|
        # replace / with other char
        url_escaped = url.gsub %r{/}, ' '
        dss = dss.merge(
          "rss-#{i}".to_sym =>
            "RSS/RSS entries from source #{i + 1} (#{url_escaped})"
        )
      end
      [dss]
    end
  end

  on_rss_timer do
    Plugin.call :rss_fetch

    interval = UserConfig[:rss_fetch_interval] * 60 # seconds
    Reserver.new(interval) { Plugin.call :rss_timer }
  end

  # on boot
  Delayer.new do
    Plugin.call :rss_init
    Plugin.call :rss_timer
  end
end

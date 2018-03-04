# frozen_string_literal: true

require 'feedjira'

require_relative 'model/site'
require_relative 'model/entry'

Plugin.create :rss do
  on_rss_fetch do
    Thread.new do
      UserConfig[:rss_sources].each_with_index do |url, i|
        begin
          notice "processing RSS source #{i}"

          feed = Feedjira::Feed.fetch_and_parse url
          site = Plugin::RSS::Site.new title: feed.title, perma_link: feed.url
          entries = feed.entries.map do |entry|
            Plugin::RSS::Entry.new(
              site: site,
              title: entry.title,
              author: entry.author,
              content: entry.content,
              created: entry.updated,
              perma_link: entry.links.first
            )
          end

          notice "got #{entries.length} entries"

          Plugin.call :extract_receive_message, "rss-#{i}".to_sym, entries
          Plugin.call :extract_receive_message, :rss, entries
        rescue => e
          puts e.to_s
          puts e.backtrace
        end
      end
    end
  end
end

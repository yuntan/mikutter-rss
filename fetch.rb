# frozen_string_literal: true

# for `Time.rfc2822` and `Time.parse`
require 'time'
require 'feed-normalizer'
require 'open-uri'

require_relative 'model/site'
require_relative 'model/entry'

# needed for anti-bot protected sites
HTTP_OPTIONS = {
  'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) ' \
  'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36'
}.freeze

Plugin.create :rss do
  on_rss_fetch do
    UserConfig[:rss_sources].each_with_index do |url, i|
      SerialThread.new do
        notice "processing RSS source #{i}"

        feed = FeedNormalizer::FeedNormalizer.parse open(url, HTTP_OPTIONS)

        begin
          feed.clean!
        rescue ArgumentError # fix for GitHub issue #1
          warn $!
        end

        site = get_site feed
        entries = feed.entries.map { |entry| get_entry site, entry }

        notice "got #{entries.length} entries for source #{i}"

        Plugin.call :extract_receive_message, "rss-#{i}".to_sym, entries
        Plugin.call :extract_receive_message, :rss, entries
      end
    end
  end

  def get_site(feed)
    Plugin::RSS::Site.new(
      title: feed.title,
      perma_link: URI.parse(feed.url),
      # image: feed.image
    )
  end

  def get_entry(site, entry)
    Plugin::RSS::Entry.new(
      site: site,
      title: entry.title,
      author: entry.authors.first,
      content: entry.content,
      created: get_created(entry),
      perma_link: URI.parse(entry.urls.first)
    )
  end

  def get_created(entry)
    if !entry.date_published.nil?
      date = entry.date_published
    elsif !entry.last_updated.nil?
      date = entry.last_updated
    else
      return Time.now
    end

    return date.localtime if date.is_a? Time

    begin
      Time.rfc2822(date).localtime
    rescue ArgumentError
      Time.parse(date).localtime
    rescue ArgumentError
      Time.now
    end
  end
end

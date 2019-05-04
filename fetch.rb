# frozen_string_literal: true

require 'open-uri'
require 'rss'

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
        notice "processing RSS source #{i} (#{url})"

        begin
          source = open(url, HTTP_OPTIONS)
        # fix for https://github.com/yuntan/mikutter-rss/issues/2
        rescue OpenURI::HTTPError, Errno::ECONNRESET => err
          error "Failed to open #{url}"
          error "#{err.class}: #{err.message}"
          next
        rescue => err
          error "Unknown error for #{url}"
          error "#{err.class}: #{err.message}"
          error err
          next
        end

        item = begin
                 RSS::Parser.parse source
               rescue RSS::InvalidRSSError => err
                 error "Invalid source. Parse without validation."
                 error "#{err.class}: #{err.message}"
                 RSS::Parser.parse source, false # parse without validation
               end

        case item
        when RSS::RDF
          notice "RSS source #{i} is RSS 1.0"
          warn "RSS 1.0 not supported."
        when RSS::Rss
          notice "RSS source #{i} is RSS 0.9x/2.0"
        when RSS::Atom::Feed
          notice "RSS source #{i} is Atom"
        when nil
          error "Invalid source. skipping."
          next
        end

        site = get_site item
        entries = item.items.map { |entry| get_entry site, entry }

        notice "got #{entries.length} entries for source #{i}"

        Plugin.call :extract_receive_message, "rss-#{i}".to_sym, entries
        Plugin.call :extract_receive_message, :rss, entries
      end
    end
  end

  def get_site(item)
    case item
    when RSS::Rss
      Plugin::RSS::Site.new(
        title: item.channel.title,
        perma_link: parse_url(item.channel.link),
      )
    when RSS::Atom::Feed
      Plugin::RSS::Site.new(
        title: item.title.content,
        perma_link: parse_url(item.link.href),
      )
    end
  end

  def get_entry(site, entry)
    case entry
    when RSS::Rss::Channel::Item
      pub_date = entry.pubDate&.localtime
      Plugin::RSS::Entry.new(
        site: site,
        title: entry.title,
        created: pub_date || Time.now,
        modified: pub_date || Time.now,
        perma_link: parse_url(entry.link),
      ).tap do |e|
        e[:subparts_images] = [parse_url(entry.enclosure.url)] if entry.enclosure
      end
    when RSS::Atom::Feed::Entry
      published = entry.published&.content&.localtime
      updated = entry.updated&.content&.localtime
      Plugin::RSS::Entry.new(
        site: site,
        title: entry.title.content,
        created: published || updated || Time.now,
        modified: updated || published || Time.now,
        perma_link: parse_url(entry.link.href),
      ).tap do |e|
        content = entry.content&.content
        e[:subparts_images] = get_image_urls content if content
      end
    end
  end

  def parse_url(s)
    # 非ASCII文字を含むURLを扱えるようにする
    # fix for https://github.com/yuntan/mikutter-rss/issues/3
    URI.parse URI.encode s
  end

  def get_image_urls(html)
    doc = Nokogiri::HTML html
    doc.search('img').map { |img| img['src'] }
  end
end

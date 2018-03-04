# frozen_string_literal: true

Plugin.create :rss do
  # initialization of settings
  UserConfig[:rss_fetch_interval] ||= 60
  UserConfig[:rss_sources] ||= []
  UserConfig[:rss_strip_content] ||= true
  UserConfig[:rss_strip_content_length] ||= 140

  settings 'RSS' do
    adjustment 'RSS fetch interval (in minutes)', :rss_fetch_interval, 15, 120
    multi 'RSS source URLs', :rss_sources
    boolean 'Strip content', :rss_strip_content
    adjustment 'Strip length', :rss_strip_content_length, 140, 1000
  end
end

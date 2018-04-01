# frozen_string_literal: true

Plugin.create :rss do
  # initialization of settings
  UserConfig[:rss_fetch_interval] ||= 60
  UserConfig[:rss_sources] ||= []

  settings 'RSS' do
    adjustment 'RSS fetch interval (in minutes)', :rss_fetch_interval, 15, 120
    multi 'RSS source URLs', :rss_sources
  end
end

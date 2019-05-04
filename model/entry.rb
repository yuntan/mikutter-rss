# frozen_string_literal: true

require 'nokogiri'

require_relative 'site'

class Plugin
  module RSS
    # model represent a RSS entry as a message
    class Entry < Diva::Model
      include Diva::Model::MessageMixin

      register :rss_entry, name: 'RSS entry', timeline: true

      field.has    :site, Site, required: true
      field.string :title, required: true # for basis model
      field.time   :created, required: true
      field.time   :modified, required: true
      # should be implemented for message model
      field.uri :perma_link, required: true

      entity_class Diva::Entity::URLEntity

      def icon
        # TODO use favicon
        # site.icon
        ::Skin['rss.png']
      end

      # should be implemented for message model
      def user
        site
      end

      # should be implemented for message model
      def description
        @description ||= dehtmlize title
      end

      # * replace <a> tags with plain text
      # * remove HTML tags
      def dehtmlize(html)
        doc = Nokogiri::HTML html

        # replace <code> with `` (markdown like syntax)
        doc.search('code').each { |code| code.replace "`#{code.text}`" }

        doc.text.delete("\n").strip
      end
    end
  end
end

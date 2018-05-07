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
      field.string :author
      field.string :title, required: true # for basis model
      field.string :content, required: true
      field.time   :created, required: true
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
        @description ||=
          "#{dehtmlize title} #{get_image_urls(content).join(' ')}".strip
      end

      # for mikutter-subparts_image plugin
      # def subparts_images
      #   return @_subparts_images if @_subparts_images
      #
      #   doc = Nokogiri::HTML html
      #   @_subparts_images = doc.search('img').map { |img| img['src'] }
      # end

      # * replace <a> tags with plain text
      # * remove HTML tags
      def dehtmlize(html)
        doc = Nokogiri::HTML html

        # replace <code> with `` (markdown like syntax)
        doc.search('code').each { |code| code.replace "`#{code.text}`" }

        doc.text.delete("\n").strip
      end

      def get_image_urls(html)
        doc = Nokogiri::HTML html
        doc.search('img').map { |img| img['src'] }
      end
    end
  end
end

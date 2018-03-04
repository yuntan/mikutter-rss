# frozen_string_literal: true

require 'nokogiri'

require_relative 'site'
require_relative '../entity/anchor_link_entity'

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

      entity_class Plugin::RSS::AnchorLinkEntity

      # should be implemented for message model
      def user
        site
      end

      # should be implemented for message model
      def description
        @description ||= begin
          s = "#{dehtmlize(title).strip}\n\n#{dehtmlize(content).strip}"
          s[0, UserConfig[:rss_strip_content_length]] + '…'
        end
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

        # replace <br> with new line
        # https://stackoverflow.com/a/10174385/2707413
        doc.search('br').each { |br| br.replace "\n" }

        doc.search('img').each do |img|
          a = "<a href=\"#{img['src']}\">🖼️</a>"
          if img.parent.name == 'a'
            img.parent.replace a
          else
            img.replace a
          end
        end

        # escape <a> for AnchorLinkEntity
        doc.search('a').each do |a|
          if a.text.strip.empty?
            a.replace ''
          else
            a.replace Nokogiri::XML::Text.new(
              "<a href=\"#{a['href']}\">#{a.text.strip}</a>", doc
            )
          end
        end

        # replace <code> with `` (markdown line syntax)
        doc.search('code').each { |code| code.replace "`#{code.text}`" }

        # insert new lines
        doc.search('p').each { |p| p.replace "\n#{p.text}\n" }
        doc.text
           .gsub(/\n+/, "\n") # remove duplicated new lines
           .gsub(/^\n/, '')
      end

      def dehtmlize_reloaded(html)
        # TODO: rewrite with HTML to markdown converter
      end
    end
  end
end

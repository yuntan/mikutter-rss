# frozen_string_literal: true

class Plugin
  module RSS
    # model represents a RSS source as an user model
    # https://reference.mikutter.hachune.net/model/2016/10/01/model-usermixin.html
    class Site < Diva::Model
      include Diva::Model::UserMixin

      register :rss_site, name: 'RSS site'

      field.string :title, required: true
      field.uri :perma_link
      # field.string :profile_image_url

      # should be implemented for user model
      def name
        title
      end

      # should be implemented for user model
      def icon
        # TODO: use favicon
        ::Skin['rss.png']
      end
    end
  end
end

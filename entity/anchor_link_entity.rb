class Plugin
  module RSS
    AnchorLinkEntity = Diva::Entity::RegexpEntity.filter(
      %r{<a [^>]*>[^<]*</a>},
      generator: lambda do |h|
        if h[:url] =~ %r{<a [^>]*href="([^"]*)"[^>]*>([^<]*)</a>}
          h[:url] = h[:open] = Regexp.last_match[1]
          h[:face] = Regexp.last_match[2]
        end
        h
      end
    )
  end
end

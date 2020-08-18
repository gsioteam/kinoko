module URI
  class Parsed
    def hostname
      host
    end
  end
end

class PageURL
  def initialize url
    p "init #{url}"
    @uri = URI.parse url
  end

  def origin
    str = "#{@uri.scheme}://#{@uri.hostname}"
  end

  def href src
    if src.match(/^\w+:/)
      src
    elsif src[0] == '/'
      origin + src
    else
      bsegs = @uri.path.split '/'
      segs = src.split '/'
      segs.each do |seg|
        if seg == '.'
        elsif seg == '..'
          bsegs.pop
        else
          bsegs << seg
        end
      end
      path = bsegs * '/'
      path = "/#{path}" unless path[0] == '/'
      origin + path
    end
  end
end
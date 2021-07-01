
class ChapterCollection < GS::Collection 
  
  ERROR = 1
  SUCCESS = 3

  BASE_URL = 'http://www.dm5.cn'
  CHAPTER_PATH = '/chapterfun.ashx'

  def initialize data
    @url = data.link
    @env = GS::ScriptContext.create 'v8'
  end

  # def load_pages page, state, &block
  #   url = "#{BASE_URL}#{CHAPTER_PATH}?cid=#{state[:cid]}&page=#{page+1}&language=1&gtk=6&_cid=#{state[:cid]}&_mid=#{state[:mid]}&_dt=#{GS::Encoder.urlEncode(state[:dt])}&_sign=#{state[:sign]}"
        
  #   req = GS::Request.create 'GET', url
  #   req.setHeader 'Referer', BASE_URL
  #   @callback = GS::Callback.block do 
  #     if req.has_error
  #       yield GS::Error.create(302, "Request error " + req.getError)
  #     else
  #       body = req.getResponseBody
  #       text = body.to_s;

  #       arr = @env.eval(text)
  #       res = []
  #       arr.each_with_index do |img_url, index|
  #         item = GS::DataItem.create 
  #         item.picture = img_url
  #         setDataAt item, page + index
  #       end
  #       if page + arr.size >= state[:total]
  #         yield nil
  #       else
  #         load_pages page + arr.size, state, &block
  #       end
  #     end
  #   end
  #   req.setOnComplete @callback
  #   req.start
  # end

  # def load_url url
  #   req = GS::Request.create 'GET', url
  #   @callback = GS::Callback.block do 
  #     if req.has_error
  #       yield GS::Error.create(302, "Request error " + req.getError)
  #     else
  #       body = req.getResponseBody
  #       doc = GS::GumboNode.parse body
  #       script = doc.querySelector 'script:not([src])'
  #       @env.eval "var window={location:{}}; function reseturl(){}"
  #       @env.eval script.text
  #       state = {
  #         total: @env.eval('DM5_IMAGE_COUNT'),
  #         cid: @env.eval('DM5_CID'),
  #         curl: @env.eval('DM5_CURL_END'),
  #         sign: @env.eval('DM5_VIEWSIGN'),
  #         mid: @env.eval('COMIC_MID'),
  #         dt: @env.eval('DM5_VIEWSIGN_DT')
  #       }
  #       load_pages 0, state do |error|
  #         yield error
  #       end
  #     end
  #   end
  #   req.setOnComplete @callback
  #   req.start
  # end

  def load_url url
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.has_error
        yield GS::Error.create(302, "Request error " + req.getError)
      else
        body = req.getResponseBody
        doc = GS::GumboNode.parse body
        scripts = doc.querySelectorAll('script:not([src])')
        script = nil
        scripts.each do |s|
          if s.text[/^eval\(/]
            script = s.text
          else
          end
        end
        if script
          @env.eval script
          arr = @env.eval 'newImgs'
          if arr.size
            result = []
            arr.each do |url|
              item = GS::DataItem.create
              item.picture = url
              result << item
            end
            setData result
            yield nil
            return
          end
        end
        yield GS::Error.create(301, "No Pages ")
      end
    end
    req.setOnComplete @callback
    req.start
  end

  def reload _, cb
    load_url @url do |error|
      cb.call error
    end
    return true
  end

end

$exports = GS::Callback.block do |data| 
  ChapterCollection.create data
end
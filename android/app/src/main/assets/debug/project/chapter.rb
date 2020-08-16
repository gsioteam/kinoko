
class ChapterCollection < GS::Collection 
  
  ERROR = 1
  DATA = 2
  SUCCESS = 3

  def initialize data
    @url = data.link
    @env = GS::ScriptContext.create 'v8'
  end

  def load_url url, state
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.has_error
        yield ERROR, GS::Error.create(302, "Request error " + req.getError)
      else
        body = req.getResponseBody
        doc = GS::GumboNode.parse(body, 'gbk')
        script = doc.querySelector('script:not([src])')
        @env.eval script.text
        @page_count = @env.eval 'DM5_IMAGE_COUNT'
        cid = @env.eval 'DM5_CID'
        curl = @env.eval 'DM5_CURL_END'
        sign = @env.eval 'DM5_VIEWSIGN'
        p "pagecount #{@page_count} cid #{cid} curl #{curl}"

      end
    end
    req.setOnComplete @callback
    req.start
  end

  def reload _, cb
    load_url @url, {}
  end

end

$exports = GS::Callback.block do |data| 
  ChapterCollection.create data
end
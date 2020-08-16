
class BookCollection < GS::Collection

  def initialize data
    @url = data.link
  end

  def fetch url
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.has_error
        yield GS::Error.create(302, "Request error " + req.getError) 
      else
        body = req.getResponseBody
        if body
          yield nil, GS::GumboNode.parse(body)
        else
          yield GS::Error.create(301, "Response null body")
        end
      end
    end
    req.setOnComplete @callback
    req.start
  end

  def reload _, cb
    purl = PageURL.new @url
    fetch @url do |error, doc|
      if error
        cb.call error
      else
        links = doc.querySelectorAll '.view-win-list li > a'
        result = []
        links.each do |link|
          item = GS::DataItem.create 
          item.link = purl.href link.attr('href')
          item.title = link.text.gsub(/ +/, ' ')
          result << item
        end
        setData result
        cb.call nil
      end
    end
    true
  end

end

$exports = GS::Callback.block do |data| 
  BookCollection.create data
end
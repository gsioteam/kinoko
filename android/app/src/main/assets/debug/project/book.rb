
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
        info_data.summary = doc.querySelector('.detail-desc').text
        info_data.subtitle = doc.querySelectorAll('.detail-main-info-author a').map{|a| a.text}.join(',')
        links = doc.querySelectorAll '#tempc > ul > li > a'
        result = []
        links.each do |link|
          item = GS::DataItem.create 
          item.link = purl.href link.attr('href')
          title = link.querySelector('.detail-list-2-info-title')
          if title 
            item.title = title.text.gsub(/ +/, ' ') 
          else
            item.title = link.text.gsub(/ +/, ' ')
          end
          if link.querySelector('.detail-list-2-info-right')
            item.subtitle = 'VIP'
          end
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
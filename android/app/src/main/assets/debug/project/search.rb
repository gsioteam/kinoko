
class SearchCollection < GS::Collection
  def initialize data
    @url = data[:url]
    @page = 0
  end

  def make_url key, page
    @url.gsub('{0}', GS::Encoder.urlEncode(key)).gsub('{1}', (page + 1).to_s)
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

  def reload data, cb
    @key = data[:key] || @key
    page = data[:page] || 0
    url = make_url(@key, page)
    page_url = PageURL.new url

    fetch url do |error, doc|
      if error
        cb.apply error
      else
        result = []
        list = doc.querySelectorAll '.book-list li'
        list.each do |node|
          item = GS::DataItem.create
          item.picture = node.querySelector('.book-list-cover-img').attr 'src'
          item.title = node.querySelector('.book-list-info-title').text
          tmp = node.querySelector('.book-list-info-bottom-item')
          item.subtitle = tmp.text if tmp
          item.link = page_url.href(node.querySelector('.book-list-info > a').attr 'href')
          result << item
        end
        @page = page
        setData result
        cb.apply nil
      end
    end
  end

  def loadMore cb 
    page = @page + 1
    url = make_url(@key, page)
    page_url = PageURL.new url

    fetch url do |error, doc|
      if error
        cb.apply error
      else
        result = []
        list = doc.querySelectorAll '.book-list li'
        list.each do |node|
          item = GS::DataItem.create
          item.picture = node.querySelector('.book-list-cover-img').attr 'src'
          item.title = node.querySelector('.book-list-info-title').text
          tmp = node.querySelector('.book-list-info-bottom-item')
          item.subtitle = tmp.text if tmp
          item.link = page_url.href(node.querySelector('.book-list-info > a').attr 'href')
          result << item
        end
        @page = page
        appendData result
        cb.apply nil
      end
    end
  end
end

$exports = GS::Callback.block do |data|
  SearchCollection.create data
end
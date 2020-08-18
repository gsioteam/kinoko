
PER_PAGE = 40

class Collection < GS::Collection
  def initialize data
    @url = data[:url]
  end

  def fetch url
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.has_error
        yield GS::Error.create(302, "Request error " + req.getError)
      else
        body = req.getResponseBody;
        if body
          yield nil, GS::GumboNode.parse(body);
        else
          yield GS::Error.create(301, "Response null body")
        end
      end
    end
    req.setOnComplete @callback
    req.start
  end
end

class HomeCollection < Collection 
  
  def reload _, cb
    page_url = PageURL.new @url
    fetch @url do |error, doc|
      if error
        cb.call error
      else
        list = doc.querySelectorAll '.manga-list'
        result = []
        list.each do |node|
          item = GS::DataItem.create
          item.type = GS::DataItem::Header
          title = node.querySelector '.manga-list-title'
          item.title = title.text.gsub('更多', '').strip
          result << item
          
          book_nodes = node.querySelectorAll '.swiper-slide > li > a'
          book_nodes.each do |book_node|
            item = GS::DataItem.create
            item.link = page_url.href(book_node.attr 'href')
            item.title = book_node.attr 'title'
            item.picture = book_node.querySelector('img.manga-list-1-cover-img').attr(src)
            item.subtitle = book_node.querySelector('.manga-list-1-tip').text
            result << item
          end
        end

        setData(result);
        cb.call nil
      end
    end
    true
  end 
end

class ListCollection < GS::Collection
  def initialize data
    @url = data[:url]
    @page = 0
  end

  def fetch url
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.getError.length > 0
        yield GS::Error.create(302, "Request error " + req.getError)
      else
        body = req.getResponseBody;
        if body
          yield nil, JSON.parse(body.to_s)
        else
          yield GS::Error.create(301, "Response null body")
        end
      end
    end
    req.setOnComplete @callback
    req.start
  end

  def load_page page, cb
    fetch @url.gsub('{0}', (page + 1).to_s).gsub('{1}', PER_PAGE.to_s) do |error, json|
      if error
        cb.call error
      else
        @page = page
        result = []
        items = json['UpdateComicItems']
        items.each do |ditem|
          item = GS::DataItem.create
          item.picture = ditem['ShowPicUrlB']
          item.title = ditem['Title']
          item.subtitle = ditem['Author'].join ','
          item.link = "http://www.dm5.cn/#{ditem['UrlKey']}" 
          result << item
        end if items
        yield result
        cb.call nil
      end
    end
  end

  def reload data, cb
    page = data[:page] || 0
    load_page page, cb do |result|
      setData result
    end
    true
  end

  def loadMore cb
    page = @page + 1
    load_page page, cb do |result|
      appendData result
    end
    true
  end
end

$exports = GS::Callback.block do |info|
  id = info[:id]
  case id
  when 'update'
    HomeCollection.create info
  else
    ListCollection.create info
  end
end
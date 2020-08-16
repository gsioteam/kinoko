
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
        node = doc.querySelector '.index-title-select'
        img_node = doc.querySelector '.index-title .index-title-logo'
        titles = node.querySelectorAll 'li > a'
        items = doc.querySelectorAll '.index-manga.index-update'
        len = [titles.size, items.size].min

        result = []
        len.times do |i|
          item = GS::DataItem.create
          item.type = GS::DataItem::Header
          item.title = titles[i].text
          item.picture = img_node.getAttribute 'src'
          result << item

          item_node = items[i]
          list_items = item_node.querySelectorAll '.mh-list .mh-item'
          list_items.each do |list_item|
            item = GS::DataItem.create
            style = list_item.querySelector('.mh-cover').getAttribute('style')
            item.picture = style[/(?<=\()[^\)]+/]
            link = list_item.querySelector('.mh-item-detali > .title a')
            item.title = link.text
            item.link = page_url.href link.getAttribute('href')
            item.subtitle = list_item.querySelector('.mh-item-detali .chapter').text
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
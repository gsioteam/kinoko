
class Collection < GS::Collection
  def initialize data
    @url = data[:url]
  end

  def fetch url
    req = GS::Request.create 'GET', url
    @callback = GS::Callback.block do 
      if req.getError
        yield GS::Error.create(302, "Request error " + req.getError)
      else
        body = req.getResponseBody;
        if body
          yield nil, GS::GumboNode.parse(body, 'gbk');
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
    fetch @url do |error, result|
      if error
        cb.call error
      else
        node = doc.querySelector '.index-title-select'
        titles = node.querySelectorAll 'li > a'
        items = doc.querySelectorAll '.index-manga.index-update'
        len = [titles.size, items.size].min

        result = []
        len.times do |i|
          item = GS::DataItem.create
          item.type = GS::DataItem::Header
          item.title = titles[i].text
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

$exports = GS::Callback.block do |info|
  HomeCollection.create info
end
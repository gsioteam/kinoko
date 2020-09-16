
const Collection = require('./collection');

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
        this.page = 0;
    }

    async fetch(url)  {
        console.log("Start " + url);
        let purl = new PageURL(url);
        let doc = await super.fetch(url);
        let results = [];
        let containers = doc.querySelectorAll('.index-container');
        for (let container of containers) {
            let header = container.querySelector('h2');
            if (header) {
                let head = glib.DataItem.new();
                head.type = glib.DataItem.Type.Header;
                head.picture = '/red-flag.png';
                head.title = header.text.trim();
                results.push(head);
            }

            let books = container.querySelectorAll('.gallery > a');
            for (let book_elem of books) {
                let item = glib.DataItem.new();
                let title = book_elem.querySelector('.caption').text.trim();
                let subtitle = title;
                if (title.length > 20) {
                    title = title.substr(0, 20) + '...';
                }
                item.type = glib.DataItem.Type.Book;
                item.title = title;
                item.subtitle = subtitle;
                item.link = purl.href(book_elem.getAttribute('href'));
                item.picture = purl.href(book_elem.querySelector('img').getAttribute('data-src'));
                results.push(item);
            }
        }
        return results;
    }

    makeURL(key, page) {
        return this.url.replace("{0}", glib.Encoder.urlEncode(this.key)).replace("{1}", page + 1);
    }

    reload(data, cb) {
        console.log("What?");
        this.key = data.get("key") || this.key;
        let page = data.get("page") || 0;
        if (!this.key) return false;
        this.fetch(this.makeURL(this.key, page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    } 

    loadMore(cb) {
        let page = this.page + 1;
        let url = this.makeURL(this.key, page);
        console.log(url);
        this.fetch(url).then((results)=>{
            this.page = page;
            this.appendData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(data) {
    console.log(data.toObject());
    return SearchCollection.new(data ? data.toObject() : {});
};

const Collection = require('./collection');

class HomeCollection extends Collection {

    constructor(data) {
        super(data);
        this.page = 0;
    }

    makeURL(page) {
        return this.url.replace('{0}', page + 1);
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
                item.type = glib.DataItem.Type.Data;
                item.title = title;
                item.subtitle = subtitle;
                item.link = purl.href(book_elem.getAttribute('href'));
                item.picture = purl.href(book_elem.querySelector('img').getAttribute('data-src'));
                results.push(item);
            }
        }
        console.log("Complete " + results.length);
        return results;
    }

    reload(data, cb) {
        let page = data.get("page") || 0;
        this.fetch(this.makeURL(page)).then((results)=>{
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
        this.fetch(this.makeURL(page)).then((results)=>{
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
};

module.exports = function(info) {
    return HomeCollection.new(info.toObject());
};
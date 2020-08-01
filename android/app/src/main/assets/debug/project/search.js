
class Collection extends glib.Collection {

    constructor(data) {
        super();
        this.url = data.url;
    }

    fetch(url) {
        return new Promise((resolve, reject)=>{
            let req = glib.Request.new('GET', url);
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        resolve(glib.GumboNode.parse(body, 'gbk'));
                    } else {
                        reject(glib.Error.new(301, "Response null body"));
                    }
                }
            });
            req.setOnComplete(this.callback);
            req.start();
        });
    }

}

class SearchCollection extends Collection {
    
    constructor(data) {
        super(data);
        this.page = 0;
    }

    loadPage(url, func) {
        let purl = new PageURL(url);
        console.log("load " + url);
        this.fetch(url).then((doc) => {
            let results = [];
            let boxes = doc.querySelectorAll('#classify_container > li');
            console.log("loaded  " + boxes.length);
            for (let box of boxes) {
                let linkimg = box.querySelector('.ImgA');
                let item = glib.DataItem.new();
                item.link = purl.href(linkimg.getAttribute('href'));
                item.picture = purl.href(linkimg.querySelector('img').getAttribute('src'));
                
                item.title = box.querySelector('.txtA').text;
                item.subtitle = box.querySelector('.info').text;
                results.push(item);
            }
            func(null, results);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            func(err);
        });
    }

    makeUrl(key, page) {
        return this.url.replace("{0}", glib.Encoder.urlEncodeWithEncoding(this.key, 'gkb')).replace("{1}", page + 1);
    }

    reload(data, cb) {
        this.key = data.get("key") || this.key;
        let page = data.get("page") || 0;
        if (!this.key) return false;
        let url = this.makeUrl(this.key, page);
        console.log(url);
        this.loadPage(url, (err, data) => {
            if (!err) {
                this.setData(data);
                this.page = page;
            }
            cb.apply(err);
        });
        return true;
    } 

    loadMore(cb) {
        let page = this.page + 1;
        let url = this.makeUrl(this.key, page);
        console.log("load more " + url);
        this.loadPage(url, (err, data) => {
            if (!err) {
                this.appendData(data);
                this.page = page;
            }
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function(data) {
    console.log(data.toObject());
    return SearchCollection.new(data ? data.toObject() : {});
};
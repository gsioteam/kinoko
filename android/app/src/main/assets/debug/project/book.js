
class BookCollection extends glib.Collection {

    constructor(data) {
        super();
        this.url = data.link;
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

    reload(cb) {
        let purl = new PageURL(this.url);
        let info_data = this.info_data;
        this.fetch(this.url).then(function (doc) {
            let links = doc.querySelectorAll("#list > li > a");
            let results = [];
            info_data.subtitle = doc.querySelector('.sub_r > .txtItme').text;
            info_data.summary = doc.querySelector('.txtDesc').text;
            console.log(`Get links ${links.length}`);
            for (let i = 0, t = links.length; i < t; i++) {
                let el = links[i];
                let item = glib.DataItem.new();
                item.link = purl.href(el.getAttribute('href'));
                item.title = el.text;
                results.push(item);
            }
            cb.apply(null, results);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err, null);
        });
    }
}

module.exports = function(data) {
    return BookCollection.new(data);
};
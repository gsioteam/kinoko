
class BookCollection extends glib.Collection {

    constructor(data) {
        super();
        this.url = data.link;
    }

    initialize() {
        this.temp = "temp.xml";
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

    reload(_, cb) {
        let purl = new PageURL(this.url);
        let info_data = this.info_data;
        this.fetch(this.url).then((doc) => {
            let imgs = doc.querySelectorAll("#thumbnail-container a.gallerythumb > img");
            let images = [];
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Chapter;
            item.url = this.url + '/1';
            for (let i = 0, t = imgs.length; i < t; i++) {
                let el = imgs[i];
                images.push(el.attr('data-src'));
            }
            info_data.data = {
                images: images
            };
            this.setData([item]);
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
    return BookCollection.new(data);
};
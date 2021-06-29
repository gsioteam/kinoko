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
                        resolve(glib.GumboNode.parse(body));
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

module.exports = Collection;
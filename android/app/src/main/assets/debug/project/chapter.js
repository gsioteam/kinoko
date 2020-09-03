
class ChapterCollection extends glib.Collection {

    request(url) {
        return new Promise((resolve, reject) => {
            let req = glib.Request.new('GET', url);
            req.setCacheResponse(true);
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        let res = glib.GumboNode.parse(body, 'gbk');
                        resolve(res);
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
        let url = this.info_data.link;
        this.request(url).then((doc) => {
            let scripts = doc.querySelectorAll("script:not([src])");
            let ctx = glib.ScriptContext.new('js');
            ctx.eval("var window = {}");
            for (let src of scripts) {
                let script = src.text.trim();
                if (script.match('JSON.parse')) {
                    ctx.eval(script);
                }
            }
            let media_url = ctx.eval('window._reader.media_url');
            let pages = ctx.eval('window._gallery.images.pages');
            let media_id = ctx.eval('window._gallery.media_id');
            let results = [];
            for (let i = 0, t = pages.length; i < t; ++i) {
                let page = pages[i];
                let item = glib.DataItem.new();
                let ext;
                switch (page.t) {
                    case 'j': ext = 'jpg'; break;
                    case 'p': ext = 'png'; break;
                    default: ext = 'jpg'; break;
                }
                item.picture = media_url + 'galleries/' + media_id + '/' + (i + 1) + '.' + ext;
                item.link = url;
                results.push(item);
            }
            this.setData(results);
            cb.apply(null);
        }).catch(function (err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            console.error(err.msg);
            cb.apply(err);
        });
        return true;
    }
}

module.exports = function (data) {
    return ChapterCollection.new(data);
};
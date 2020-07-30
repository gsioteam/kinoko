
class ChapterCollection extends glib.Collection {

    request(url, text) {
        return new Promise((resolve, reject) => {
            let req = glib.Request.new('GET', url);
            req.setCacheResponse(true);
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        let res = text ? body.text() : glib.GumboNode.parse(body, 'gbk');
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

    async loadProcess(url) {
        let ctx = glib.ScriptContext.new('v8');
        ctx.eval('document = {write: function(html) {return html;}};');
        let cache = {}, count = 0;
        
        while (url) {
            let purl = new PageURL(url);
            let doc = await this.request(url);
            let tags = doc.querySelectorAll('script[src]');
            for (let tag of tags) {
                let src = tag.getAttribute('src');
                if (src.match(/^\/js/)) {
                    let href = purl.href(src);
                    if (!cache[href]) {
                        cache[href] = true;
                        let script = await this.request(href, true);
                        console.log(`eval(${script})`);
                        ctx.eval(script);
                    }
                }
            }
            try {
                let script = doc.querySelector('script:not([src])');
                let html = ctx.eval(script.text);
                let doc2 = glib.GumboNode.parse2(html);
                let link = doc2.querySelector('a');
                let item = glib.DataItem.new();
                item.picture = link.querySelector('img').getAttribute('src');
                item.link = url;
                url = purl.href(link.getAttribute('href'));
                this.setDataAt(item, count);
                count++;
            }catch (e) {
                break;
            }
        }
    }

    reload(_, cb) {
        console.log("**start reload");
        this.loadProcess(this.info_data.link).then(function () {
            console.log("**reload complete");
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
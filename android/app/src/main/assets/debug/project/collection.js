class Collection extends glib.Collection {

    constructor(data) {
        super(data);
        this.url = data.url || data.link;
    }

    fetch(url) {
        return new Promise((resolve, reject)=>{
            console.log("start request " + url);
            let req = glib.Request.new('GET', url);
            req.setHeader('User-Agent', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36');
            req.setHeader('Accept-Language', 'en-US,en;q=0.9');
            this.callback = glib.Callback.fromFunction(function() {
                if (req.getError()) {
                    reject(glib.Error.new(302, "Request error " + req.getError()));
                } else {
                    let body = req.getResponseBody();
                    if (body) {
                        console.log("request complete!");
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

class ParsedCollection extends Collection {
    async fetch(url) {
        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('#list_container dl');
        let results = [];
        for (let node of nodes) {
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Book;
            let link = node.querySelector('.book-list a');
            item.link = link.attr('href');
            item.title = link.querySelector('b').text;
            let pnodes = node.querySelectorAll('.book-list p');
            if (pnodes.length != 0) {
                item.subtitle = pnodes[pnodes.length - 1].text;
            } else {
                let subnode = node.querySelector('.book-list i');
                if (subnode) item.subtitle = subnode.text;
            }
            item.picture = node.querySelector('dt img').attr('src');
            results.push(item);
        }
        return results;
    }
}

class DesktopCollection extends glib.Collection {

    constructor(data) {
        super(data);
        this.url = data.url || data.link;
    }

    fetch(url) {
        return new Promise((resolve, reject)=>{
            let req = glib.Request.new('GET', url);
            req.setHeader('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36');
            req.setHeader('Accept-Language', 'en-US,en;q=0.9');
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

class ParsedDesktopCollection extends DesktopCollection {
    async fetch(url) {
        let doc = await super.fetch(url);
        let nodes = doc.querySelectorAll('.direlist .bookinfo');
        let results = [];
        for (let node of nodes) {
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Book;
            let link = node.querySelector('dt a');
            item.link = link.attr('href');
            item.picture = link.querySelector('img').attr('src');
            item.title = node.querySelector('.bookname').text;
            item.subtitle = node.querySelector('.chaptername').text;
            results.push(item);
        }
        return results;
    }
}

module.exports = {
    Collection,
    ParsedCollection,
    DesktopCollection,
    ParsedDesktopCollection
};
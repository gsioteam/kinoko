
class Collection extends glib.Collection {
    
    init(data) {
        this.url = data.url;
        this.name = data.title;
    }

    reload(cb) {
        console.log("reload!");
        let url = this.url;
        let req = glib.Request.new('GET', this.url);
        this.callback = glib.Callback.fromFunction(function() {
            if (req.getError()) {
                console.log("Request error " + req.getError());
                cb(glib.Error.new(302, "Request error " + req.getError()));
            } else {
                let body = req.getResponseBody();
                let results = [];
                if (body) {
                    let purl = new PageURL(url);
                    let doc = glib.GumboNode.parse(body, 'gbk');
                    let boxes = doc.querySelectorAll('.imgBox');
                    console.log(`Found ${boxes.length} imageBox`);
                    for (let box of boxes) {
                        let subhead = box.querySelector('.Sub_H2');
                        if (subhead) {
                            let head = glib.DataItem.new();
                            head.type = glib.DataItem.Type.Header;
                            let icon = subhead.querySelector('.icon img');
                            if (icon) {
                                head.picture = purl.href(icon.getAttribute('src'));
                            }
                            let label = subhead.querySelector('.Title');
                            if (label) {
                                head.title = label.text;
                            }
                            results.push(head);
                        }
                        let books = box.querySelectorAll('ul > li');
                        for (let book_elem of books) {
                            let item = glib.DataItem.new();
                            item.title = book_elem.querySelector('a.txtA').text;
                            item.summary = book_elem.querySelector('.info').text;
                            item.link = purl.href(book_elem.querySelector('a.ImgA').getAttribute('href'));
                            item.picture = purl.href(book_elem.querySelector('a.ImgA > img').getAttribute('src'));
                            results.push(item);
                        }
                    }
                    console.log("result " + results.length);
                    cb.apply(null, results);
                } else {
                    console.log("Null body");
                    cb.apply(glib.Error.new(301, "Response null body"), null);
                }
            }
        });
        req.setOnComplete(this.callback);
        req.start();
        return true;
    }

    loadMore(cb) {

    }
};

module.exports = function(info) {
    let col = Collection.new();
    col.init(info.toObject());
    return col;
};
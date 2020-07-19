
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

class HomeCollection extends Collection {

    reload(cb) {
        let purl = new PageURL(this.url);
        this.fetch(this.url).then(function(doc){
            let results = [];
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
                    item.subtitle = book_elem.querySelector('.info').text;
                    item.link = purl.href(book_elem.querySelector('a.ImgA').getAttribute('href'));
                    item.picture = purl.href(book_elem.querySelector('a.ImgA > img').getAttribute('src'));
                    results.push(item);
                }
            }
            console.log("result " + results.length);
            cb.apply(null, results);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err, null);
        });
        return true;
    }
};

class UpdateCollection extends Collection {

    reload(cb) {
        let purl = new PageURL(this.url);
        this.fetch(this.url).then(function(doc){
            let results = [];
            let boxes = doc.querySelectorAll('.UpdateList .itemBox');
            console.log(`Found ${boxes.length} imageBox`);
            for (let box of boxes) {
                let linkimg = box.querySelector('.itemImg a');
                let item = glib.DataItem.new();
                item.title = linkimg.getAttribute('title');
                item.link = purl.href(linkimg.getAttribute('href'));
                item.picture = purl.href(linkimg.querySelector('img').getAttribute('src'));
                let items = box.querySelectorAll('.itemTxt > .txtItme');
                let summary = [];
                console.log("Link " + items.length);
                for (const elem of items) {
                    summary.push(elem.text);
                }
                item.subtitle = summary.join('|');
                results.push(item);
            }
            console.log("result " + results.length);
            cb.apply(null, results);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err, null);
        });
        return true;
    }
}

module.exports = function(info) {
    let col;
    let data = info.toObject();
    switch (data.id) {
        case 'home': {
            col = HomeCollection.new(data);
            break;
        }
        case 'update': {
            col = UpdateCollection.new(data);
            break;
        }
    }
    return col;
};
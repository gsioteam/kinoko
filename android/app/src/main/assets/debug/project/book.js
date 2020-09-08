
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

    reload(_, cb) {
        let purl = new PageURL(this.url);
        let info_data = this.info_data;
        this.fetch(this.url).then((doc) => {
            let imgs = doc.querySelectorAll("#thumbnail-container a.gallerythumb > img");
            let images = [];
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Chapter;
            item.link = this.url + '/1';
            for (let i = 0, t = imgs.length; i < t; i++) {
                let el = imgs[i];
                images.push(el.attr('data-src'));
            }
            info_data.picture = doc.querySelector('#cover img').attr('data-src');
            let titles = doc.querySelectorAll('#info > .title');
            info_data.title = titles[0].text
            info_data.subtitle = titles[1].text;
            let tags = doc.querySelectorAll('#tags .tag-container:not(.hidden)');
            let dataTags = [];
            for (let i = 0, t = tags.length; i < t; ++i) {
                let tag = tags[i];
                let children = tag.children;
                let title;
                for (let child of children) {
                    if (child.type == glib.GumboNode.Type.Text) {
                        let text = child.text.trim();
                        if (text.length > 0) {
                            title = text;
                            break;
                        }
                    }
                }
                let links = [];
                let tagLinks = tag.querySelectorAll('.tags > a.tag');
                console.log("size : " + tagLinks.length + "  title:" + title);
                for (let link of tagLinks) {
                    try {
                        let data = {
                            link: purl.href(link.attr('href')),
                            name: link.querySelector('.name').text,
                        };
                        console.log("push name " + data.name);
                        let count = link.querySelector('.count');
                        if (count) data.count = count.text;
                        links.push(data);
                    } catch (e) {
                        console.log("Error : " + e.message);
                    }
                }
                dataTags.push({
                    title: title,
                    links: links
                });
            }
            info_data.data = {
                images: images,
                tags: dataTags
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
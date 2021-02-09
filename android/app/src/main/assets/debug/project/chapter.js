const {Collection} = require('./collection');

class ChapterCollection extends Collection {

    async request(root_url) {
        let url = root_url.replace(/(-\d+)*\.html$/i, '-10-1.html');
        let doc = await this.fetch(url);

        let options = doc.querySelectorAll('select.sl-page option');
        let urls = [];
        for (let i = 1, t = options.length; i < t; i++) {
            urls.push(root_url.replace(/(-\d+)*\.html$/i, `-10-${i+1}.html`));
        }

        let offset = 0;
        offset = this.parseDoc(doc, root_url, offset);
        for (let i = 0, t = urls.length; i < t; ++i) {
            let url = urls[i];
            let doc = await this.fetch(url);
            offset = this.parseDoc(doc, root_url, offset);
        }
    }

    parseDoc(doc, root_url, offset) {
        let imgs = doc.querySelectorAll('.pic_box > img');
        for (let i = 0, t = imgs.length; i < t; ++i) {
            let img = imgs[i];
            let item = glib.DataItem.new();
            item.picture = img.attr('src');
            console.log("parse "+item.picture);
            let index = offset + i;
            item.link = root_url.replace(/(-\d+)*\.html$/i, `-${index}.html`);
            this.setDataAt(item, index);
        }
        return offset + imgs.length;
    }

    reload(_, cb) {
        let url = this.info_data.link;
        this.request(url).then(() => {
            cb.apply(null);
        }).catch((err) => {
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
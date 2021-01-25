const {Collection} = require('./collection');
const {LZString} = require('./lzstring');

class BookCollection extends Collection {

    async fetch(url) {
        let pageUrl = new PageURL(url);

        let doc = await super.fetch(url);
        let lists = doc.querySelectorAll('.chapter-list'), results = [];
        if (lists.length === 0) {
            let stateNode = doc.querySelector('#__VIEWSTATE');
            if (stateNode) {
                let ctx = glib.ScriptContext.new('v8');
                ctx.eval(LZString);
                let html = ctx.eval('LZString.decompressFromBase64("' + stateNode.attr('value') + '")');
                doc = glib.GumboNode.parse2(html);
                lists = doc.querySelectorAll('.chapter-list');
            }
        }
        for (let list of lists) {
            let ul_arr = list.querySelectorAll('ul').reverse();
            for (let ul of ul_arr) {
                let li_arr = ul.querySelectorAll('li > a');
                for (let li of li_arr) {
                    let item = glib.DataItem.new();
                    item.type = glib.DataItem.Type.Chapter;
                    item.title = li.attr('title');
                    console.log(`title ${item.title}`);
                    item.link = pageUrl.href(li.attr('href'));
                    item.subtitle = li.querySelector('i').text;
                    results.push(item);
                }
            }
        }
        return results;
    }

    reload(_, cb) {
        console.log("reload");
        this.fetch(this.url).then((results) => {
            this.setData(results);
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
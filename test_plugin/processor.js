const bookFetch = require('./book_fetch');

/**
 * @property {String}key need override the key for caching
 * @method load need override,
 * @method checkNew need override
 */
class MangaProcesser extends Processor {

    // The key for caching data
    get key() {
        return this.data.link;
    }

    /**
     * 
     * Start load pictures
     * 
     * @param {*} state The saved state.
     */
    async load(state) {
        let url = this.data.link;

        async function request(url)  {
            let res = await fetch(url);
            let text = await res.text();
            return HTMLParser.parse(text);
        }

        const doc = await request(url);

        let scripts = doc.querySelectorAll("script:not([src])");
        let ctx = new ScriptContext();
        ctx.eval("var window = {}");
        for (let src of scripts) {
            let script = src.text.trim();
            if (script.match('JSON.parse')) {
                ctx.eval(script);
            }
        }
        let imgSrc = doc.querySelector('#image-container img').getAttribute('src');
        let imgUrl = new URL(imgSrc);
            
        let media_url = `${imgUrl.protocol}//${imgUrl.host}/`;
        let pages = ctx.eval('window._gallery.images.pages');
        let media_id = ctx.eval('window._gallery.media_id');
        let results = [];
        for (let i = 0, t = pages.length; i < t; ++i) {
            let page = pages[i];
            let ext;
            switch (page.t) {
                case 'j': ext = 'jpg'; break;
                case 'p': ext = 'png'; break;
                case 'g': ext = 'gif'; break;
                default: ext = 'jpg'; break;
            }
            console.log("type " + page.t + " ext " + ext);
            results.push({
                url: media_url + 'galleries/' + media_id + '/' + (i + 1) + '.' + ext
            });
        }
        this.setData(results);

        this.save(true, {});
    }

    async fetch(url) {
        let res = await fetch(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36',
            }
        });
        let buffer = await res.arrayBuffer();
        let decoder = new TextDecoder('gbk');
        let text = decoder.decode(buffer);
        return HTMLParser.parse(text);
    }

    // Called in `dispose`
    unload() {

    }

    // Check for new chapter
    async checkNew() {
        let url = this.data.link + '?waring=1';
        let data = await bookFetch(url);
        var item = data.list[data.list.length - 1];
        /**
         * @property {String}title The last chapter title.
         * @property {String}key The unique identifier of last chpater.
         */
        return {
            title: item.title,
            key: item.link,
        };
    }
}

module.exports = MangaProcesser;
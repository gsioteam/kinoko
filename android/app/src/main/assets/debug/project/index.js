
const {ParsedCollection, ParsedDesktopCollection, Collection} = require('./collection');

class NoPageCollection extends ParsedCollection {

    makeURL() {
        let lang = this.getSetting('language');
        return this.url.replace('{0}', lang);
    }

    reload(_, cb) {
        let url = this.makeURL();
        console.log(url);
        this.fetch(url).then((results)=>{
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
};

class PageCollection extends ParsedDesktopCollection {
    constructor(data) {
        super(data);
        this.page = 0;
    }


    makeURL(page) {
        let lang = this.getSetting('language');
        return this.url.replace('{0}', lang).replace('{1}', page + 1);
    }

    reload(data, cb) {
        let page = data["page"] || 0;
        this.fetch(this.makeURL(page)).then((results)=>{
            this.page = page;
            this.setData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }

    loadMore(cb) {
        let page = this.page + 1;
        this.fetch(this.makeURL(page)).then((results)=> {
            this.page = page;
            this.appendData(results);
            cb.apply(null);
        }).catch(function(err) {
            if (err instanceof Error) 
                err = glib.Error.new(305, err.message);
            cb.apply(err);
        });
        return true;
    }
}

class HomeCollection extends Collection {
    async fetch(url) {
        let doc = await super.fetch(url);
        let tabs = doc.querySelectorAll('nav.mid-menu .change_tab');
        let contents = doc.querySelectorAll('ul.tab_content');

        let results = [];

        for (let i = 0, t = tabs.length; i < t; ++i) {
            let tab = tabs[i];
            let header = glib.DataItem.new();
            header.type = glib.DataItem.Type.Header;
            header.title = tab.text;
            results.push(header);

            let tab_content = contents[i];
            let books = tab_content.querySelectorAll('li a');
            for (let link of books) {
                let item = glib.DataItem.new();
                item.type = glib.DataItem.Type.Book;
                item.title = link.attr('title');
                item.link = link.attr('href');
                item.picture = link.querySelector('img').attr('src');
                results.push(item);
            }
        }

        let box = doc.querySelector('.middle-box');
        let header = glib.DataItem.new();
        header.type = glib.DataItem.Type.Header;
        header.title = box.querySelector('h1').text.trim();
        results.push(header);

        let nodes = box.querySelectorAll('dl');
        for (let node of nodes) {
            let item = glib.DataItem.new();
            item.type = glib.DataItem.Type.Book;
            let link = node.querySelector('.book-list a');
            item.link = link.attr('href');
            item.title = link.querySelector('b').text;
            item.subtitle = node.querySelector('.book-list > i').text;
            item.picture = node.querySelector('dt img').attr('src');
            results.push(item);
        }
        return results;
    }

    makeURL() {
        let lang = this.getSetting('language');
        return this.url.replace('{0}', lang);
    }

    reload(_, cb) {
        this.fetch(this.makeURL()).then((results)=>{
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

module.exports = function(info) {
    let data = info.toObject();
    switch (data.id) {
        case 'home': {
            return HomeCollection.new(data);
        }
        case 'manga_directory': {
            return PageCollection.new(data);
        }
        default: {
            return NoPageCollection.new(data);
        }
    }
};

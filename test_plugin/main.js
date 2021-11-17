const supportLanguages = require('./supoort_languages');

class MainController extends Controller {

    load(data) {
        this.id = data.id;
        this.url = data.url;
        this.page = 0;

        var cached = this.readCache();
        let list;
        if (cached) {
            list = cached.items;
        } else {
            list = [];
        }

        this.data = {
            list: list,
            loading: false,
            hasMore: this.id === 'manga_directory'
        };

        this.userAgent = this.id == 'manga_directory' ? 
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' : 
        'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Mobile Safari/537.36';

        if (cached) {
            let now = new Date().getTime();
            if (now - cached.time > 30 * 60 * 1000) {
                this.reload();
            }
        } else {
            this.reload();
        }

    }

    async onPressed(index) {
        await this.navigateTo('book', {
            data: this.data.list[index]
        });
    }

    onRefresh() {
        this.reload();
    }

    async onLoadMore() {
        this.setState(() => {
            this.data.loading = true;
        });
        try {

            let page = this.page + 1;
            let url = this.makeURL(page);
            let res = await fetch(url, {
                headers: {
                    'User-Agent': this.userAgent,
                    'Accept-Language': 'en-US,en;q=0.9',
                }
            });
            let text = await res.text();
            this.page = page;
            let items = this.parseData(text, url);
    
            this.setState(()=>{
                for (let item of items) {
                    this.data.list.push(item);
                }
                this.data.loading = false;
                this.data.hasMore = items.length > 0;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
        
    }

    getLanguage() {
        let lan = localStorage['cached_language'];
        if (lan) return lan;

        for (let name of supportLanguages) {
            if (navigator.language.startsWith(name)) {
                return name;
            }
        }
        return 'en';
    }

    makeURL(page) {
        return this.url.replace('{0}', this.getLanguage()).replace('{1}', page + 1);
    }

    async reload() {
        this.setState(() => {
            this.data.loading = true;
        });
        try {
            let url = this.makeURL(0);
            let res = await fetch(url, {
                headers: {
                    'User-Agent': this.userAgent,
                    'Accept-Language': 'en-US,en;q=0.9',
                }
            });
            let text = await res.text();
            let items = this.parseData(text);
            this.page = 0;
            localStorage['cache_' + this.id] = JSON.stringify({
                time: new Date().getTime(),
                items: items,
            });
            console.log(`Items ${items.length}`);
            this.setState(()=>{
                this.data.list = items;
                this.data.loading = false;
                this.data.hasMore = items.length > 0;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    readCache() {
        let cache = localStorage['cache_' + this.id];
        if (cache) {
            let json = JSON.parse(cache);
            return json;
        }
    }

    parseData(text) {
        if (this.id === 'home') {
            return this.parseHomeData(text);
        } else if (this.id === 'manga_directory') {
            return this.parsePageData(text);
        } else {
            return this.parseNoPageData(text);
        }
    }

    parseHomeData(html) {
        console.log(html);
        const doc = HTMLParser.parse(html);

        let tabs = doc.querySelectorAll('nav.mid-menu .change_tab');
        let contents = doc.querySelectorAll('ul.tab_content');

        let results = [];

        for (let i = 0, t = tabs.length; i < t; ++i) {
            let tab = tabs[i];
            results.push({
                header: true,
                title: tab.text,
            });

            let tab_content = contents[i];
            let books = tab_content.querySelectorAll('li a');
            for (let link of books) {
                results.push({
                    title: link.getAttribute('title'),
                    link: link.getAttribute('href'),
                    picture: link.querySelector('img').getAttribute('src'),
                });
            }
        }

        let box = doc.querySelector('.middle-box');
        results.push({
            header: true,
            title: box.querySelector('h1').text.trim(),
        });

        let nodes = box.querySelectorAll('dl');
        for (let node of nodes) {
            let link = node.querySelector('.book-list a');
            results.push({
                link: link.getAttribute('href'),
                title: link.querySelector('b').text,
                subtitle: node.querySelector('.book-list > i').text,
                picture: node.querySelector('dt img').getAttribute('src')
            });
        }
        return results;
    }

    parsePageData(html) {
        const doc = HTMLParser.parse(html);

        let nodes = doc.querySelectorAll('.direlist .bookinfo');
        let results = [];
        for (let node of nodes) {
            let link = node.querySelector('dt a');
            results.push({
                link: link.getAttribute('href'),
                title: node.querySelector('.bookname').text,
                subtitle: node.querySelector('.chaptername').text,
                picture: link.querySelector('img').getAttribute('src')
            });
        }
        return results;
    }

    parseNoPageData(html) {
        const doc = HTMLParser.parse(html);

        let nodes = doc.querySelectorAll('#list_container dl');
        let results = [];
        for (let node of nodes) {
            let link = node.querySelector('.book-list a');
            let item = {
                link: link.getAttribute('href'),
                title: link.querySelector('b').text,
                picture: node.querySelector('dt img').getAttribute('src')
            };
            let pnodes = node.querySelectorAll('.book-list p');
            if (pnodes.length != 0) {
                item.subtitle = pnodes[pnodes.length - 1].text;
            } else {
                let subnode = node.querySelector('.book-list i');
                if (subnode) item.subtitle = subnode.text;
            }
            results.push(item);
        }
        return results;
    }
}

module.exports = MainController;
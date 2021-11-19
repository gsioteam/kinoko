const bookFetch = require('./book_fetch');

class BookController extends Controller {

    /**
     * 
     * @property {String}key The unique identifier of the favorite item
     * @property {String}title The name of book
     * @property {String}subtitle The subtitle of book
     * @property {String}picture The cover of book.
     * @property {Object}data Data will be sent to book page.
     * @property {String}page The book page path.
     */
    get bookInfo() {
        return {
            key: this.url,
            title: this.data.title,
            subtitle: this.data.subtitle,
            picture: this.data.picture,
            page: 'book',
            data: {
                link: this.url,
                title: this.data.title,
                subtitle: this.data.subtitle,
                picture: this.data.picture,
                summary: this.data.summary,
            },
        };
    }

    async load(data) {
        this.data = {
            title: data.title,
            subtitle: data.subtitle,
            summary: data.summary,
            picture: data.picture,
            loading: false,
            editing: false,
            reverse: localStorage['reverse'] != 'false',
            list: []
        };
        this.selected = [];

        this.url = data.link;
        
        /**
         * Add history record
         * 
         * Same as addFavorite with out lastData.
         */
        this.addHistory(this.bookInfo);
        console.log(`Data ${JSON.stringify(this.bookInfo)}`);
        
        let cached = localStorage[`book:${this.url}`];
        if (cached) {
            let data = JSON.parse(cached);
            this.data.title = data.title;
            if (data.subtitle) this.data.subtitle = data.subtitle;
            if (data.summary) this.data.summary = data.summary;
            this.data.list = data.list;

            let now = new Date().getTime();
            if (now - (data.time || 0) > 30 * 60 * 1000) {
                this.reload();
            }
        } else {
            this.reload();
        }
    }

    unload() {

    }

    onRefresh() {
        this.reload();
    }

    async reload() {
        this.setState(()=>{
            this.data.loading = true;
        });
        try {
            let url = this.url + '?waring=1';
            let data = await bookFetch(url);
    
            let now = new Date().getTime();
            data.time = now;
            localStorage[`book:${this.url}`] = JSON.stringify(data);
    
            this.setState(()=>{
                this.data.title = data.title;
                if (data.subtitle) this.data.subtitle = data.subtitle;
                if (data.summary) this.data.summary = data.summary;
                this.data.list = data.list;
                this.data.loading = false;
            });
        } catch (e) {
            showToast(`${e}\n${e.stack}`);
            this.setState(()=>{
                this.data.loading = false;
            });
        }
    }

    onFavoritePressed() {
        this.setState(()=>{
            if (this.isFavarite()) {
                FavoritesManager.remove(this.url);
            } else {
                let last;
    
                /**
                 * Add to favorites list
                 * 
                 * The first argument see `bookinfo`
                 * 
                 * The second argument is optional
                 * @param {String}title The title of the last chapter
                 * @param {String}key The unique identifier of the last chapter
                 */
                if (this.data.list.length > 0) {
                    let data = this.data.list[this.data.list.length - 1];
                    last = {
                        title: data.title,
                        key: data.link,
                    };
                }
                this.addFavorite(this.bookInfo, last);
            }
        });
    }

    onDownloadPressed() {
        this.setState(()=>{
            this.data.editing = true;
        });
    }

    onClearPressed() {
        this.selected = [];
        this.setState(()=>{
            this.data.editing = false;
        });
    }
    
    onCheckPressed() {
        let downloads = [];
        for (let idx of this.selected) {
            var data = this.data.list[idx];
            /**
             * Add to download queue
             * 
             * @param {String}key The unique identifier of the download item
             * @param {String}title The name of book
             * @param {String}subtitle The subtitle of book
             * @param {String}link The url of book, To group items with same book link.
             * @param {String}picture The cover of book.
             * @param {Object}data Data will be sent to processor load function.
             * @param {String*}data.title The title of chapter. 
             */
            downloads.push({
                key: data.link,
                title: this.data.title,
                link: this.url,
                picture: this.data.picture,
                subtitle: this.data.subtitle,
                data: data,
            });
        }
        this.addDownload(downloads);

        this.selected = [];
        this.setState(()=>{
            this.data.editing = false;
        });
    }

    onPressed(idx) {
        if (this.data.editing) {
            this.setState(()=>{
                let loc = this.selected.indexOf(idx);
                if (loc >= 0) {
                    this.selected.splice(loc, 1);
                } else {
                    this.selected.push(idx);
                }
            });
        } else {
            this.openBook({
                list: this.data.list,
                index: idx,
            });
        }
    }

    isSelected(index) {
        return this.selected.indexOf(index) >= 0;
    }

    onSourcePressed() {
        this.openBrowser(this.url);
    }

    onOrderSelected(value) {
        this.setState(()=>{
            this.data.reverse = value;
            localStorage['reverse'] = value.toString();
        });
    }

    isDownloaded(index) {
        let item = this.data.list[index];
        return DownloadManager.exist(item.link);
    }

    isFavarite() {
        return FavoritesManager.exist(this.url);
    }
}

module.exports = BookController;
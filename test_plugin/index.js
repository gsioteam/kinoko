class IndexController extends Controller {
    load() {
        this.data = {
            tabs: [
                {
                    "title": "Home",
                    "id": "home",
                    "url": "https://{0}.ninemanga.com/"
                },
                {
                    "title": "Latest Release",
                    "id": "last_release",
                    "url": "https://{0}.ninemanga.com/list/New-Update/"
                },
                {
                    "title": "Manga Directory",
                    "id": "manga_directory",
                    "url": "https://{0}.ninemanga.com/category/index_{1}.html"
                },
                {
                    "title": "Hot Manga",
                    "id": "hot_manga",
                    "url": "https://{0}.ninemanga.com/list/Hot-Book/"
                },
                {
                    "title": "New Manga",
                    "id": "new_manga",
                    "url": "https://{0}.ninemanga.com/list/New-Book/"
                }, 
            ]
        };
    }
}

module.exports = IndexController;
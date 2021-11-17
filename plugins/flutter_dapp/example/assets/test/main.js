
class MainController extends Controller {

    load() {
        console.log('in load');
        this.data = {
            'list': [
                {
                    'img': 'https://picsum.photos/id/201/200/300.jpg',
                    'title': 'Title1',
                    'subtitle': 'subtitle1'
                },{
                    'img': 'https://picsum.photos/id/202/200/300.jpg',
                    'title': 'Title12',
                    'subtitle': 'subtitle2'
                },{
                    'img': 'https://picsum.photos/id/203/200/300.jpg',
                    'title': 'Title3',
                    'subtitle': 'subtitle3'
                },{
                    'img': 'https://picsum.photos/id/204/200/300.jpg',
                    'title': 'Title4',
                    'subtitle': 'subtitle4'
                },{
                    'img': 'https://picsum.photos/id/209/200/300.jpg',
                    'title': 'Title5',
                    'subtitle': 'subtitle5'
                },{
                    'img': 'https://picsum.photos/id/206/200/300.jpg',
                    'title': 'Title6',
                    'subtitle': 'subtitle6'
                },{
                    'img': 'https://picsum.photos/id/210/200/300.jpg',
                    'title': 'Title7',
                    'subtitle': 'subtitle7'
                },{
                    'img': 'https://picsum.photos/id/208/200/300.jpg',
                    'title': 'Title8',
                    'subtitle': 'subtitle8'
                }
            ]
        };
        this.testLoad();
    }

    async onPressed(index) {
        console.log("onPressed " + index);
        var data = this.data.list[index];
        await this.navigateTo('picture', {
            data: {
                src: data.img
            }
        });
        console.log("After push");
    }

    async testLoad() {
        let res = await fetch("https://api.github.com/repos/gsioteam/kumav_env/issues/1/comments");
        console.log(await res.text());
    }
}

module.exports = MainController;
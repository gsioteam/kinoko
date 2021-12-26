
class TestController extends Controller {
    load() {
    }

    async loadEnd(url) {
        try {
            const webview = this.findElement('webview');
            console.log(`loadEnd ${url}`);
            console.log(await webview.eval("document.querySelector('html').outerHTML"));
            console.log(JSON.stringify(await webview.getCookies("https://www.google.com")));
        } catch (e) {
            console.log(`Error ${e}`);
        }
    }

    async testHeadless() {
        // Hold the reference otherwise the webview will be release before loading complete.
        this.webview = new HeadlessWebView({
            resourceReplacements: [{
                // `test` will be compile to a ExgEx.
                test:'jwplayer\.js',
                resource: this.loadString('my_jwplayer.js'),
                mimeType: 'text/javascript',
            }]
        });
        this.webview.onloadstart = (url) => {
            console.log(`[HeadlessWebView] loadStart ${url}`);
        };
        this.webview.onloadend = async (url) => {
            console.log(`[HeadlessWebView] loadEnd ${url}`);
            console.log(await this.webview.eval("document.querySelector('html').outerHTML"));
        };
        this.webview.onfail = (url, error) => {
            console.log(`[HeadlessWebView] loadFailed ${url} ${error}`);
        };
        /**
         * Invoke when the web site call `messenger.send('message', data)`
         */
        this.webview.onmessage = (data) => {
            console.log(`[HeadlessWebView] onMessage ${data}`);
        };
        this.webview.load("https://www.google.com");
    }
}

module.exports = TestController;
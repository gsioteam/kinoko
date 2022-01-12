const supportLanguages = require('./supoort_languages');

class SettingsController extends Controller {

    load() {
        this.data = {
            languages: supportLanguages,
            map: {
                'en': 'English',
                'es': 'Español',
                'ru': 'русский',
                'de': 'Deutsch',
                'it': 'Italiano',
                'br': 'Brasil',
                'fr': 'Français'
            },
            current: this.getLanguage(),
        };
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

    onPressed(lan) {
        this.setState(() => {
            this.data.current = lan;
            localStorage['cached_language'] = lan;
            console.log(`Set language ${lan}`);
        });
        localStorage.removeItem('cache_home');
        localStorage.removeItem('cache_last_release');
        localStorage.removeItem('cache_manga_directory');
        localStorage.removeItem('cache_hot_manga');
        localStorage.removeItem('cache_new_manga');
        NotificationCenter.trigger("reload", null);
    }
}

module.exports = SettingsController;
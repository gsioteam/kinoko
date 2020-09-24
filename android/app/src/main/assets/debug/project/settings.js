

class SettingsController extends glib.Collection {
    reload(data, cb) {
        this.setData([
            glib.SettingItem.new(
                glib.SettingItem.Type.Header,
                "general",
                "General"
            ),
            glib.SettingItem.new(
                glib.SettingItem.Type.Options,
                "language",
                "Language",
                "en",
                [{
                    name: 'English',
                    value: 'en'
                }, {
                    name: 'Español',
                    value: 'es'
                }, {
                    name: 'русский',
                    value: 'ru'
                }, {
                    name: 'Deutsch',
                    value: 'de'
                }, {
                    name: 'Italiano',
                    value: 'it'
                }, {
                    name: 'Brasil',
                    value: 'br'
                }, {
                    name: 'Français',
                    value: 'fr'
                }]
            ),
        ]);
    }
}

module.exports = function() {
    return SettingsController.new();
}
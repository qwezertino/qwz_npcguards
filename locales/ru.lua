local Translations = {
    menu = {
        friend = 'ДРУГ',
        neutral = 'НЕЙТРАЛЬНО',
        war = 'ВРАГ',
        respect = 'РЕСПЕКТ',
        like = 'НРАВИТСЯ',
        dislike = 'НЕНРАВИТСЯ',
        input_dialog_title = 'Установить отношения с фракциями:',
        context_menu_title = 'Управление охраной',
        context_menu_button1 = 'Редактировать отношения',
        context_menu_button1_desc = 'Открыть меню редактировани отношений с другими фракциями',

        create_dialog_title = 'Crate new Fraction with relations',
        create_dialog_label = 'Enter new Fraction name',
        create_dialog_desc = 'Usually gang name from qb-core/shared/gangs.lua',

        delete_dialog_title = 'Delete Fraction with relations',
        delete_dialog_label = 'Enter Fraction name',
        delete_dialog_desc = 'Usually gang name from qb-core/shared/gangs.lua',

        update_dialog_title = 'Delete Fraction with relations',
        update_dialog_label = 'Enter Fraction name',
        update_dialog_desc = 'Usually gang name from qb-core/shared/gangs.lua',

        admin_title = 'Relations Control Panel',
        admin_create = 'Create new Fraction',
        admin_create_desc = 'Create new Fraction and relations table',
        admin_update = 'Update Fraction',
        admin_update_desc = 'Update relations between fractions!',
        admin_delete = 'Delete Fraction',
        admin_delete_desc = 'Delete fraction with all relations!',
    },
    ped = {
        target_menu_open = 'Открыть меню редактирования'
    },
    commands = {
        store_gangs_relation = 'Add to DB all gangs with neutral relations',
        create_new_relation = 'Create a new Fraction and relations table',
        update_relation = 'Updates relations between fractions!',
        delete_relation = 'Delete fraction with all relations!',
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

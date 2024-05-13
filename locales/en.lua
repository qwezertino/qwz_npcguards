local Translations = {
    menu = {
        friend = 'FRIEND',
        neutral = 'NEUTRAL',
        war = 'WAR',
        respect = 'RESPECT',
        like = 'LIKE',
        dislike = 'DISLIKE',
        input_dialog_title = 'Set relations with Gangs:',
        context_menu_title = 'Guards Control Panel',
        context_menu_button1 = 'Edit relations',
        context_menu_button1_desc = 'Open menu for edit relations with other gangs',

        create_dialog_title = 'Crate new Fraction with relations',
        create_dialog_label = 'Enter new Fraction name',
        create_dialog_desc = 'Usually gang name from qb-core/shared/gangs.lua',

        delete_dialog_title = 'Delete Fraction with relations',
        delete_dialog_label = 'Enter Fraction name',
        delete_dialog_desc = 'Usually gang name from qb-core/shared/gangs.lua',

        update_dialog_title = 'Update fraction with Relations',
        update_dialog_label = 'Select a Fraction',
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
        target_menu_open = 'Open Guards Menu'
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

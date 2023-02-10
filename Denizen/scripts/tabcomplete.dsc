# STEMMechanics - Tab Completion
# Written by: nomadjimbob (james@stemmechanics.com.au)
#
# Command tab completion helper
#
# License: MIT

tabcomplete_events:
    type: world
    debug: false
    events:
        on scripts loaded:
            - if <util.scripts.parse[name].contains[stemmech_feature_register]>:
                - run stemmech_feature_register def.id:tabcomplete

tabcomplete_initalize:
    type: task
    debug: false
    script:
        - if <yaml.list.contains[tabcomplete]>:
            - ~yaml unload id:tabcomplete

        - yaml create id:tabcomplete
        - flag server tabcomplete:!

        - flag server tabcomplete.mobs.hostile:<list[spider|cave_spider|enderman|zombie_pigman|piglin|zombified_piglin|evoker|vindicator|pillager|revager|ravager_jockey|vex|chicken_jockey|endermite|guardian|elder_guardian|shulker|skeleton_horseman|husk|stray|phantom|blaze|creeper|ghast|magma_cube|silverfish|slime|spider_jockey|zombie|zombie_villager|drowned|wither_skeleton|witch|hoglin|zoglin|piglin_brute|warden|skeleton]>
        - flag server tabcomplete.mobs.passive:<list[sheep|cow|fox|bat|chicken|cod|ocelot|pig|baby_piglin|baby_polar_bear|snow_golem|rabbit|salmon|mooshroom|squid|strider|tropical_fish|turtle|villager|wandering_trader|pufferfish|axolotl|glow_squid|frog|donkey|horse|cat|parrot|mule|skeleton_horse|allay]>
        - flag server tabcomplete.mobs.neutral:<list[dolphin|polar_bear|trader_llama|llama|panda|wolf|bee|iron_golem|goat|spider|cave_spider|enderman|zombie_pigman|piglin|zombiefied_piglin]>
        - flag server tabcomplete.mobs.any:<list>

        - run stemmech_feature_set_ready def.id:tabcomplete

tabcomplete_completion:
    type: task
    debug: false
    script:
        - yaml id:tabcomplete set <queue.definition_map.exclude[raw_context].values.parse[escaped].separated_by[.]>:end

tabcomplete_remove:
    type: task
    debug: false
    script:
        - yaml id:tabcomplete set <queue.definition_map.exclude[raw_context].values.parse[escaped].separated_by[.]>:!

tabcomplete:
    type: procedure
    debug: false
    definitions: command|raw_args
    script:
        - define raw_args:<[raw_args].unescaped.if_null[<empty>]>
        - define path:<[command]>
        - define "args:|:<[raw_args].split[ ]>"
        - if <[args].get[1].if_null[<empty>]> == <empty>:
            - define args:<[args].remove[1].if_null[<list>]>
        - define argsSize:<[args].size>
        - define newArg:<[raw_args].ends_with[<&sp>].or[<[raw_args].is[==].to[<empty>]>]>
        - if <[newArg]>:
            - define argsSize:+:1
        - repeat <[argsSize].sub[1]> as:index:
            - define value:<[args].get[<[index]>]>
            - define keys:<yaml[tabcomplete].list_keys[<[path]>].if_null[<list>]>
            - if <[value]> == <empty>:
                - repeat next
            - if <[keys].contains[<[value]>]>:
                - define path:<[path]>.<[value]>
            - else if <[keys].contains[*]>:
                - define path:<[path]>.*
            - else:
                - define default:<[keys].filter[starts_with[<[value]>?]].get[1].if_null[null]>
                - if <[default]> == null:
                    - define default:<[keys].filter[starts_with[_]].get[1].if_null[null]>
                    - if <[default]> == null:
                        - determine <list>
                    - else:
                        - define path:<[path]>.<[default]>
                - else:
                    - define path:<[path]>.<[default]>
            - if <yaml[tabcomplete].read[<[path]>]> == end:
                - determine <list>

        - foreach <yaml[tabcomplete].list_keys[<[path]>].parse[unescaped].if_null[<list>]> as:value_list:
            - if <[value_list].contains_text[+].if_null[false]>:
                - define value_list:<[value_list].split[+]>
            - else:
                - define value_list:<list[<[value_list]>]>

            - foreach <[value_list]>:
                - if <[value].contains_text[?]>:
                    - define perm:<[value].after[?]>
                    - if <[perm].starts_with[_]>:
                        - define option:<[perm].after[_].before[=]>
                        - define option_value:<[perm].after[=]>
                        - choose <[option]>:
                            - case gamemode:
                                - if <player.gamemode.if_null[null].equals[<[option_value]>].not>:
                                    - foreach next
                            - default:
                                - foreach next
                    - else:
                        - if !<player.has_permission[<[perm]>]>:
                            - foreach next
                    - define value:<[value].before[?]>

                - if <[value].starts_with[_]>:
                    - define value:<[value].after[_]>
                    - if <[value].starts_with[*]>:
                        - if <server.scripts.parse[name].contains[tabcomplete_<[value].after[*]>]>:
                            - define ret:|:<proc[tabcomplete_<[value].after[*]>].context[<[args]>]>
                    - if <[value].starts_with[&]>:
                        - if <[raw_args].ends_with[,]>:
                            - define parg:<[args].get[<[argsSize]>]>
                            - if <server.scripts.parse[name].contains[tabcomplete_<[value].after[&]>]>:
                                - define clist:<proc[tabcomplete_<[value].after[&]>].context[<[args]>]>
                                - foreach <[clist]>:
                                    - define ret:|:<[parg]><[value]>
                        - else:
                            - define ret:|:<proc[tabcomplete_<[value].after[&]>].context[<[args]>]>
                    - if <[value].starts_with[^]>:
                        - if <[raw_args].ends_with[,]>:
                            - define parg:<[args].get[<[argsSize]>]>
                            - define pitems:<[parg].split[,]>
                            - if <server.scripts.parse[name].contains[tabcomplete_<[value].after[^]>]>:
                                - define clist:<proc[tabcomplete_<[value].after[^]>].context[<[args]>]>
                                - foreach <[clist]>:
                                    - if !<[pitems].contains[<[value]>]>:
                                        - define ret:|:<[parg]><[value]>
                        - else:
                            - if <server.scripts.parse[name].contains[tabcomplete_<[value].after[^]>]>:
                                - define ret:|:<proc[tabcomplete_<[value].after[^]>].context[<[args]>]>
                - else:
                    - define ret:->:<[value]>
        - if !<definition[ret].exists>:
            - determine <list>
        - if <[newArg]>:
            - determine <[ret]>
        # - determine <[ret].filter[starts_with[<[args].last>]]>
        - determine <[ret].filter[contains[<[args].last>]]>

tabcomplete_gamemodes:
    type: procedure
    debug: false
    script:
        - determine <list[adventure|creative|survival|spectator]>

tabcomplete_int:
    type: procedure
    debug: false
    script:
        - determine <list[0|1|2|3|4|5|6|7|8|9]>

tabcomplete_chance:
    type: procedure
    debug: false
    script:
        - determine <list[0.1|0.2|0.3|0.4|0.5|0.6|0.7|0.8|0.9|1]>

tabcomplete_range:
    type: procedure
    debug: false
    script:
        - determine <list[1-2|1-3|1-4|2-5|3-6|4-10]>

tabcomplete_int_nozero:
    type: procedure
    debug: false
    script:
        - determine <list[1|2|3|4|5|6|7|8|9]>

tabcomplete_bool:
    type: procedure
    debug: false
    script:
        - determine <list[true|false]>

tabcomplete_blocks:
    type: procedure
    debug: false
    script:
        - determine <server.material_types.parse[name]>

tabcomplete_materials:
    type: procedure
    debug: false
    script:
        - determine <server.material_types.parse[name]>

tabcomplete_groups:
    type: procedure
    debug: false
    script:
        - determine <server.permission_groups.filter[ends_with[_edit].not].exclude[default]>

tabcomplete_durations_small:
    type: procedure
    debug: false
    script:
        - determine <list[30s|1m|2m|2m30s|3m|5m|10m|15m|20m|30m|1h]>

tabcomplete_durations:
    type: procedure
    debug: false
    script:
        - determine <list[5m|10m|15m|30m|1h|2h|4h|1d|2d|3d|1w|2w|4w]>

tabcomplete_durations_perm:
    type: procedure
    debug: false
    script:
        - determine <list[5m|10m|15m|30m|1h|2h|4h|1d|2d|3d|1w|2w|4w|perm]>

tabcomplete_pageno:
    type: procedure
    debug: false
    script:
        - determine <list[1|2|3|4|5|6|7|8|9]>

tabcomplete_onlineplayers:
    type: procedure
    debug: false
    script:
        - determine <server.online_players.parse[name]>

tabcomplete_players:
    type: procedure
    debug: false
    script:
        - determine <server.players.parse[name]>

tabcomplete_npcs:
    type: procedure
    debug: false
    script:
        - determine <server.npcs.parse[id]>

tabcomplete_worlds:
    type: procedure
    debug: false
    script:
        - determine <server.worlds.parse[name]>

tabcomplete_hostile:
    type: procedure
    debug: false
    script:
        - determine <server.flag[tabcomplete.mobs.hostile].if_null[<list>]>

tabcomplete_passive:
    type: procedure
    debug: false
    script:
        - determine <server.flag[tabcomplete.mobs.passive].if_null[<list>]>

tabcomplete_neutral:
    type: procedure
    debug: false
    script:
        - determine <server.flag[tabcomplete.mobs.neutral].if_null[<list>]>

tabcomplete_entities:
    type: procedure
    debug: false
    script:
        - define entity_list:<list>
        - define entity_list:<[entity_list].include[<server.flag[tabcomplete.mobs.hostile].if_null[<list>]>]>
        - define entity_list:<[entity_list].include[<server.flag[tabcomplete.mobs.passive].if_null[<list>]>]>
        - define entity_list:<[entity_list].include[<server.flag[tabcomplete.mobs.neutral].if_null[<list>]>]>
        - define entity_list:<[entity_list].include[<server.flag[tabcomplete.mobs.any].if_null[<list>]>]>

        - determine <[entity_list].deduplicate>

tabcomplete_regions:
    type: procedure
    debug: false
    script:
        - if <player.if_null[<empty>]> != <empty>:
            - determine <player.location.world.list_regions.parse[id]>
        - determine <list>

tabcomplete_timezone:
    type: procedure
    debug: false
    script:
        - determine <list[Etc/GMT+12|Etc/GMT+11|Pacific/Midway|Pacific/Niue|Pacific/Pago_Pago|Pacific/Samoa|US/Samoa|America/Adak|America/Atka|Etc/GMT+10|HST|Pacific/Honolulu|Pacific/Johnston|Pacific/Rarotonga|Pacific/Tahiti|SystemV/HST10|US/Aleutian|US/Hawaii|Pacific/Marquesas|AST|America/Anchorage|America/Juneau|America/Nome|America/Sitka|America/Yakutat|Etc/GMT+9|Pacific/Gambier|SystemV/YST9|SystemV/YST9YDT|US/Alaska|America/Dawson|America/Ensenada|America/Los_Angeles|America/Metlakatla|America/Santa_Isabel|America/Tijuana|America/Vancouver|America/Whitehorse|Canada/Pacific|Canada/Yukon|Etc/GMT+8|Mexico/BajaNorte|PST|PST8PDT|Pacific/Pitcairn|SystemV/PST8|SystemV/PST8PDT|US/Pacific|US/Pacific-New|America/Boise|America/Cambridge_Bay|America/Chihuahua|America/Creston|America/Dawson_Creek|America/Denver|America/Edmonton|America/Hermosillo|America/Inuvik|America/Mazatlan|America/Ojinaga|America/Phoenix|America/Shiprock|America/Yellowknife|Canada/Mountain|Etc/GMT+7|MST|MST7MDT|Mexico/BajaSur|Navajo|PNT|SystemV/MST7|SystemV/MST7MDT|US/Arizona|US/Mountain|America/Bahia_Banderas|America/Belize|America/Cancun|America/Chicago|America/Costa_Rica|America/El_Salvador|America/Guatemala|America/Indiana/Knox|America/Indiana/Tell_City|America/Knox_IN|America/Managua|America/Matamoros|America/Menominee|America/Merida|America/Mexico_City|America/Monterrey|America/North_Dakota/Beulah|America/North_Dakota/Center|America/North_Dakota/New_Salem|America/Rainy_River|America/Rankin_Inlet|America/Regina|America/Resolute|America/Swift_Current|America/Tegucigalpa|America/Winnipeg|CST|CST6CDT|Canada/Central|Canada/East-Saskatchewan|Canada/Saskatchewan|Chile/EasterIsland|Etc/GMT+6|Mexico/General|Pacific/Easter|Pacific/Galapagos|SystemV/CST6|SystemV/CST6CDT|US/Central|US/Indiana-Starke|America/Atikokan|America/Bogota|America/Cayman|America/Coral_Harbour|America/Detroit|America/Eirunepe|America/Fort_Wayne|America/Grand_Turk|America/Guayaquil|America/Havana|America/Indiana/Indianapolis|America/Indiana/Marengo|America/Indiana/Petersburg|America/Indiana/Vevay|America/Indiana/Vincennes|America/Indiana/Winamac|America/Indianapolis|America/Iqaluit|America/Jamaica|America/Kentucky/Louisville|America/Kentucky/Monticello|America/Lima|America/Louisville|America/Montreal|America/Nassau|America/New_York|America/Nipigon|America/Panama|America/Pangnirtung|America/Port-au-Prince|America/Porto_Acre|America/Rio_Branco|America/Thunder_Bay|America/Toronto|Brazil/Acre|Canada/Eastern|Cuba|EST|EST5EDT|Etc/GMT+5|IET|Jamaica|SystemV/EST5|SystemV/EST5EDT|US/East-Indiana|US/Eastern|US/Michigan|America/Caracas|America/Anguilla|America/Antigua|America/Aruba|America/Asuncion|America/Barbados|America/Blanc-Sablon|America/Boa_Vista|America/Campo_Grande|America/Cuiaba|America/Curacao|America/Dominica|America/Glace_Bay|America/Goose_Bay|America/Grenada|America/Guadeloupe|America/Guyana|America/Halifax|America/Kralendijk|America/La_Paz|America/Lower_Princes|America/Manaus|America/Marigot|America/Martinique|America/Moncton|America/Montserrat|America/Port_of_Spain|America/Porto_Velho|America/Puerto_Rico|America/Santiago|America/Santo_Domingo|America/St_Barthelemy|America/St_Kitts|America/St_Lucia|America/St_Thomas|America/St_Vincent|America/Thule|America/Tortola|America/Virgin|Antarctica/Palmer|Atlantic/Bermuda|Brazil/West|Canada/Atlantic|Chile/Continental|Etc/GMT+4|PRT|SystemV/AST4|SystemV/AST4ADT|America/St_Johns|CNT|Canada/Newfoundland|AGT|America/Araguaina|America/Argentina/Buenos_Aires|America/Argentina/Catamarca|America/Argentina/ComodRivadavia|America/Argentina/Cordoba|America/Argentina/Jujuy|America/Argentina/La_Rioja|America/Argentina/Mendoza|America/Argentina/Rio_Gallegos|America/Argentina/Salta|America/Argentina/San_Juan|America/Argentina/San_Luis|America/Argentina/Tucuman|America/Argentina/Ushuaia|America/Bahia|America/Belem|America/Buenos_Aires|America/Catamarca|America/Cayenne|America/Cordoba|America/Fortaleza|America/Godthab|America/Jujuy|America/Maceio|America/Mendoza|America/Miquelon|America/Montevideo|America/Paramaribo|America/Recife|America/Rosario|America/Santarem|America/Sao_Paulo|Antarctica/Rothera|Atlantic/Stanley|BET|Brazil/East|Etc/GMT+3|America/Noronha|Atlantic/South_Georgia|Brazil/DeNoronha|Etc/GMT+2|America/Scoresbysund|Atlantic/Azores|Atlantic/Cape_Verde|Etc/GMT+1|Africa/Abidjan|Africa/Accra|Africa/Bamako|Africa/Banjul|Africa/Bissau|Africa/Casablanca|Africa/Conakry|Africa/Dakar|Africa/El_Aaiun|Africa/Freetown|Africa/Lome|Africa/Monrovia|Africa/Nouakchott|Africa/Ouagadougou|Africa/Sao_Tome|Africa/Timbuktu|America/Danmarkshavn|Antarctica/Troll|Atlantic/Canary|Atlantic/Faeroe|Atlantic/Faroe|Atlantic/Madeira|Atlantic/Reykjavik|Atlantic/St_Helena|Eire|Etc/GMT|Etc/GMT+0|Etc/GMT-0|Etc/GMT0|Etc/Greenwich|Etc/UCT|Etc/UTC|Etc/Universal|Etc/Zulu|Europe/Belfast|Europe/Dublin|Europe/Guernsey|Europe/Isle_of_Man|Europe/Jersey|Europe/Lisbon|Europe/London|GB|GB-Eire|GMT|GMT0|Greenwich|Iceland|Portugal|UCT|UTC|Universal|WET|Zulu|Africa/Algiers|Africa/Bangui|Africa/Brazzaville|Africa/Ceuta|Africa/Douala|Africa/Kinshasa|Africa/Lagos|Africa/Libreville|Africa/Luanda|Africa/Malabo|Africa/Ndjamena|Africa/Niamey|Africa/Porto-Novo|Africa/Tunis|Africa/Windhoek|Arctic/Longyearbyen|Atlantic/Jan_Mayen|CET|ECT|Etc/GMT-1|Europe/Amsterdam|Europe/Andorra|Europe/Belgrade|Europe/Berlin|Europe/Bratislava|Europe/Brussels|Europe/Budapest|Europe/Busingen|Europe/Copenhagen|Europe/Gibraltar|Europe/Ljubljana|Europe/Luxembourg|Europe/Madrid|Europe/Malta|Europe/Monaco|Europe/Oslo|Europe/Paris|Europe/Podgorica|Europe/Prague|Europe/Rome|Europe/San_Marino|Europe/Sarajevo|Europe/Skopje|Europe/Stockholm|Europe/Tirane|Europe/Vaduz|Europe/Vatican|Europe/Vienna|Europe/Warsaw|Europe/Zagreb|Europe/Zurich|MET|Poland|ART|Africa/Blantyre|Africa/Bujumbura|Africa/Cairo|Africa/Gaborone|Africa/Harare|Africa/Johannesburg|Africa/Kigali|Africa/Lubumbashi|Africa/Lusaka|Africa/Maputo|Africa/Maseru|Africa/Mbabane|Africa/Tripoli|Asia/Amman|Asia/Beirut|Asia/Damascus|Asia/Gaza|Asia/Hebron|Asia/Istanbul|Asia/Jerusalem|Asia/Nicosia|Asia/Tel_Aviv|CAT|EET|Egypt|Etc/GMT-2|Europe/Athens|Europe/Bucharest|Europe/Chisinau|Europe/Helsinki|Europe/Istanbul|Europe/Kiev|Europe/Mariehamn|Europe/Nicosia|Europe/Riga|Europe/Sofia|Europe/Tallinn|Europe/Tiraspol|Europe/Uzhgorod|Europe/Vilnius|Europe/Zaporozhye|Israel|Libya|Turkey|Africa/Addis_Ababa|Africa/Asmara|Africa/Asmera|Africa/Dar_es_Salaam|Africa/Djibouti|Africa/Juba|Africa/Kampala|Africa/Khartoum|Africa/Mogadishu|Africa/Nairobi|Antarctica/Syowa|Asia/Aden|Asia/Baghdad|Asia/Bahrain|Asia/Kuwait|Asia/Qatar|Asia/Riyadh|EAT|Etc/GMT-3|Europe/Kaliningrad|Europe/Minsk|Indian/Antananarivo|Indian/Comoro|Indian/Mayotte|Asia/Riyadh87|Asia/Riyadh88|Asia/Riyadh89|Mideast/Riyadh87|Mideast/Riyadh88|Mideast/Riyadh89|Asia/Tehran|Iran|Asia/Baku|Asia/Dubai|Asia/Muscat|Asia/Tbilisi|Asia/Yerevan|Etc/GMT-4|Europe/Moscow|Europe/Samara|Europe/Simferopol|Europe/Volgograd|Indian/Mahe|Indian/Mauritius|Indian/Reunion|NET|W-SU|Asia/Kabul|Antarctica/Mawson|Asia/Aqtau|Asia/Aqtobe|Asia/Ashgabat|Asia/Ashkhabad|Asia/Dushanbe|Asia/Karachi|Asia/Oral|Asia/Samarkand|Asia/Tashkent|Etc/GMT-5|Indian/Kerguelen|Indian/Maldives|PLT|Asia/Calcutta|Asia/Colombo|Asia/Kolkata|IST|Asia/Kathmandu|Asia/Katmandu|Antarctica/Vostok|Asia/Almaty|Asia/Bishkek|Asia/Dacca|Asia/Dhaka|Asia/Qyzylorda|Asia/Thimbu|Asia/Thimphu|Asia/Yekaterinburg|BST|Etc/GMT-6|Indian/Chagos|Asia/Rangoon|Indian/Cocos|Antarctica/Davis|Asia/Bangkok|Asia/Ho_Chi_Minh|Asia/Hovd|Asia/Jakarta|Asia/Novokuznetsk|Asia/Novosibirsk|Asia/Omsk|Asia/Phnom_Penh|Asia/Pontianak|Asia/Saigon|Asia/Vientiane|Etc/GMT-7|Indian/Christmas|VST|Antarctica/Casey|Asia/Brunei|Asia/Choibalsan|Asia/Chongqing|Asia/Chungking|Asia/Harbin|Asia/Hong_Kong|Asia/Kashgar|Asia/Krasnoyarsk|Asia/Kuala_Lumpur|Asia/Kuching|Asia/Macao|Asia/Macau|Asia/Makassar|Asia/Manila|Asia/Shanghai|Asia/Singapore|Asia/Taipei|Asia/Ujung_Pandang|Asia/Ulaanbaatar|Asia/Ulan_Bator|Asia/Urumqi|Australia/Perth|Australia/West|CTT|Etc/GMT-8|Hongkong|PRC|Singapore|Australia/Eucla|Asia/Dili|Asia/Irkutsk|Asia/Jayapura|Asia/Pyongyang|Asia/Seoul|Asia/Tokyo|Etc/GMT-9|JST|Japan|Pacific/Palau|ROK|ACT|Australia/Adelaide|Australia/Broken_Hill|Australia/Darwin|Australia/North|Australia/South|Australia/Yancowinna|AET|Antarctica/DumontDUrville|Asia/Khandyga|Asia/Yakutsk|Australia/ACT|Australia/Brisbane|Australia/Canberra|Australia/Currie|Australia/Hobart|Australia/Lindeman|Australia/Melbourne|Australia/NSW|Australia/Queensland|Australia/Sydney|Australia/Tasmania|Australia/Victoria|Etc/GMT-10|Pacific/Chuuk|Pacific/Guam|Pacific/Port_Moresby|Pacific/Saipan|Pacific/Truk|Pacific/Yap|Australia/LHI|Australia/Lord_Howe|Antarctica/Macquarie|Asia/Sakhalin|Asia/Ust-Nera|Asia/Vladivostok|Etc/GMT-11|Pacific/Efate|Pacific/Guadalcanal|Pacific/Kosrae|Pacific/Noumea|Pacific/Pohnpei|Pacific/Ponape|SST|Pacific/Norfolk|Antarctica/McMurdo|Antarctica/South_Pole|Asia/Anadyr|Asia/Kamchatka|Asia/Magadan|Etc/GMT-12|Kwajalein|NST|NZ|Pacific/Auckland|Pacific/Fiji|Pacific/Funafuti|Pacific/Kwajalein|Pacific/Majuro|Pacific/Nauru|Pacific/Tarawa|Pacific/Wake|Pacific/Wallis|NZ-CHAT|Pacific/Chatham|Etc/GMT-13|MIT|Pacific/Apia|Pacific/Enderbury|Pacific/Fakaofo|Pacific/Tongatapu|Etc/GMT-14|Pacific/Kiritimati]>

tabcomplete_weather:
    type: procedure
    debug: false
    script:
        - determine <list[sunny|storm|thunder]>

tabcomplete_time_period:
    type: procedure
    debug: false
    script:
        - determine <list[day|night|dawn|dusk]>

tabcomplete_onoff:
    type: procedure
    debug: false
    script:
        - determine <list[on|off]>

tabcomplete_radius:
    type: procedure
    debug: false
    script:
        - determine <list[1|2|5|10|15|20|30|50]>

tabcomplete_days:
    type: procedure
    debug: false
    script:
        - determine <list[1|2|3|5|7|14|28]>

tabcomplete_date:
    type: procedure
    debug: false
    script:
        - define date_list:<list>
        - define date:<util.time_now>
        - repeat 28:
            - define date_list:->:<util.time_now.add[<[value]>d].format[yyyy/MM/dd]>
        - determine <[date_list]>

tabcomplete_time:
    type: procedure
    debug: false
    script:
        - determine <list[00:00|00:30|01:00|01:30|02:00|02:30|03:00|03:30|04:00|04:30|05:00|05:30|06:00|06:30|07:00|07:30|08:00|08:30|09:00|09:30|10:00|10:30|11:00|11:30|12:00|12:30|13:00|13:30|14:00|14:30|15:00|15:30|16:00|16:30|17:00|17:30|18:00|18:30|19:00|19:30|20:00|20:30|21:00|21:30|22:00|22:30|23:00|23:30]>

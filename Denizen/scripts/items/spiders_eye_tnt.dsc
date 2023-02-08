spiders_eye_tnt:
    type: item
    material: tnt
    mechanisms:
        custom_model_data: 15000
    display name: Spider Eyes TNT
    lore:
    - <white>TNT that explodes when it detects
    - <white>another player
    recipes:
        1:
            type: shapeless
            input:
            - spidereye|tnt|spidereye

spiders_eye_tnt_events:
    type: world
    debug: false
    events:
        on player places tnt:
            - if <context.material.item.custom_model_data> == 15000:
                - flag <context.location> spiders_eye_tnt.owner:<player>

        on player walks:
            - ratelimit <player> 20t
            - define spiders_eye_tnt_list:<player.location.find_blocks_flagged[spiders_eye_tnt].within[5]>
            - foreach <[spiders_eye_tnt_list]>:
                - if <[value].flag[spiders_eye_tnt.owner]> != <player>:
                    - flag <[value]> spiders_eye_tnt:!
                    - if <[value].material.name> == tnt:
                        - modifyblock <[value]> air
                        - drop primed_tnt <[value]>
        
        on block explodes:
            - if <context.location.has_flag[spiders_eye_tnt]>:
                - flag <[value]> spiders_eye_tnt:!
        
        on player breaks block:
            - if <context.location.has_flag[spiders_eye_tnt]>:
                - flag <[value]> spiders_eye_tnt:!

        on entity picks up tnt:
            - if <context.location.has_flag[spiders_eye_tnt]>:
                - flag <[value]> spiders_eye_tnt:!

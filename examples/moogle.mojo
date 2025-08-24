import mist._hue as hue

import mog


fn render_pixels(style: mog.Style, width: Int) -> String:
    return style.render(String("  ") * width)


alias NEWLINE = ord("\n")
alias NAME = """          .         .                                             
         ,8.       ,8.           ,o888888o.         ,o888888o.    
        ,888.     ,888.       . 8888     `88.      8888     `88.  
       .`8888.   .`8888.     ,8 8888       `8b  ,8 8888       `8. 
      ,8.`8888. ,8.`8888.    88 8888        `8b 88 8888           
     ,8'8.`8888,8^8.`8888.   88 8888         88 88 8888           
    ,8' `8.`8888' `8.`8888.  88 8888         88 88 8888           
   ,8'   `8.`88'   `8.`8888. 88 8888        ,8P 88 8888   8888888 
  ,8'     `8.`'     `8.`8888.`8 8888       ,8P  `8 8888       .8' 
 ,8'       `8        `8.`8888.` 8888     ,88'      8888     ,88'  
,8'         `         `8.`8888.  `8888888P'         `8888888P'    """

fn main():
    pass
    # # Colors
    # var BACKGROUND = mog.Style()
    # var BODY = mog.Style().background(mog.Color(0xFFFFFF))
    # var BORDER = mog.Style().background(mog.Color(0x000000))
    # var SHADOW = mog.Style().background(mog.Color(0xB5C1C7))
    # var WING = mog.Style().background(mog.Color(0xDE81AF))

    # # 16x22 grid
    # var grid_width = 16
    # var grid_height = 22
    # var builder = String()

    # # line by line painting
    # # 1
    # builder.write(render_pixels(BACKGROUND, 6), render_pixels(BORDER, 1), render_pixels(BACKGROUND, 9), NEWLINE)

    # # 2
    # builder.write(render_pixels(BACKGROUND, 5), render_pixels(BORDER, 1), render_pixels(WING, 1), render_pixels(BORDER, 1), render_pixels(BACKGROUND, 8), NEWLINE)

    # # 3
    # builder.write(render_pixels(BACKGROUND, 6), render_pixels(BORDER, 1), render_pixels(BACKGROUND, 1), render_pixels(BORDER, 1), render_pixels(BACKGROUND, 7), NEWLINE)

    # # 4
    # builder.write(render_pixels(BACKGROUND, 3), render_pixels(BORDER, 2), render_pixels(BACKGROUND, 3), render_pixels(BORDER, 1), render_pixels(BACKGROUND, 2), render_pixels(BORDER, 2), render_pixels(BACKGROUND, 3), NEWLINE)

    # # 5
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 2))
    # builder.write(render_pixels(BORDER, 6))
    # builder.write(render_pixels(SHADOW, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 6
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 4))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 7
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 2))
    # builder.write(render_pixels(BODY, 6))
    # builder.write(render_pixels(SHADOW, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 8
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 8))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 9
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 8))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 10
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 8))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 11
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(BODY, 4))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 12
    # builder.write(render_pixels(BORDER, 3))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 3))
    # builder.write(NEWLINE)

    # # 13
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(NEWLINE)

    # # 14
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 3))
    # builder.write(render_pixels(WING, 2))
    # builder.write(render_pixels(BODY, 3))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(NEWLINE)

    # # 15
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(WING, 2))
    # builder.write(render_pixels(BODY, 2))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 2))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(NEWLINE)

    # # 15
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 10))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(WING, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(NEWLINE)

    # # 15
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 10))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(NEWLINE)

    # # 16
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 8))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(NEWLINE)

    # # 17
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 8))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 1))
    # builder.write(NEWLINE)

    # # 18
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(SHADOW, 4))
    # builder.write(render_pixels(BODY, 1))
    # builder.write(render_pixels(SHADOW, 1))
    # builder.write(render_pixels(BORDER, 2))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # 19
    # builder.write(render_pixels(BACKGROUND, 3))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BODY, 3))
    # builder.write(render_pixels(SHADOW, 2))
    # builder.write(render_pixels(BODY, 3))
    # builder.write(render_pixels(BORDER, 1))
    # builder.write(render_pixels(BACKGROUND, 3))
    # builder.write(NEWLINE)

    # # 20
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(render_pixels(BORDER, 12))
    # builder.write(render_pixels(BACKGROUND, 2))
    # builder.write(NEWLINE)

    # # Name
    # var border_style = mog.Style().padding(2, 4)
    # var name_style = mog.Style().foreground(mog.Color(0xF25D94)).padding_left(2)
    # var content = mog.join_horizontal(
    #     mog.center,
    #     builder,
    #     name_style.render(NAME)
    # )

    # print(border_style.render(content))

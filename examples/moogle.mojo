import mog
import hue
from gojo.strings import StringBuilder


fn color_grid(x_steps: Int, y_steps: Int) -> List[List[hue.Color]]:
    var x0y0 = hue.Color(0xF25D94)
    var x1y0 = hue.Color(0xEDFF82)
    var x0y1 = hue.Color(0x643AFF)
    var x1y1 = hue.Color(0x14F9D5)

    var x0 = List[hue.Color](capacity=y_steps)
    for i in range(y_steps):
        x0.append(x0y0.blend_luv(x0y1, Float64(i)/Float64(y_steps)))

    var x1 = List[hue.Color](capacity=y_steps)
    for i in range(y_steps):
        x1.append(x1y0.blend_luv(x1y1, Float64(i)/Float64(y_steps)))

    var grid = List[List[hue.Color]](capacity=y_steps)
    var x = 0
    while x < y_steps:
        var y0 = x0[x]
        grid.append(List[hue.Color](capacity=x_steps))
        var y = 0
        while y < x_steps:
            grid[x].append(y0.blend_luv(x1[x], Float64(y)/Float64(x_steps)))
            y += 1
        x += 1
    return grid


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
    # Colors
    var BACKGROUND = mog.Style()
    var BODY = mog.Style().background(mog.Color(0xFFFFFF))
    var BORDER = mog.Style().background(mog.Color(0x000000))
    var SHADOW = mog.Style().background(mog.Color(0xB5C1C7))
    var WING = mog.Style().background(mog.Color(0xDE81AF))

    # 16x22 grid
    var grid_width = 16
    var grid_height = 22
    var builder = StringBuilder()

    # line by line painting
    # 1
    _ = builder.write_string(render_pixels(BACKGROUND, 6))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 9))
    _ = builder.write_byte(NEWLINE)

    # 2
    _ = builder.write_string(render_pixels(BACKGROUND, 5))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 8))
    _ = builder.write_byte(NEWLINE)

    # 3
    _ = builder.write_string(render_pixels(BACKGROUND, 6))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 7))
    _ = builder.write_byte(NEWLINE)

    # 4
    _ = builder.write_string(render_pixels(BACKGROUND, 3))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BACKGROUND, 3))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BACKGROUND, 3))
    _ = builder.write_byte(NEWLINE)

    # 5
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 2))
    _ = builder.write_string(render_pixels(BORDER, 6))
    _ = builder.write_string(render_pixels(SHADOW, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 6
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 4))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 7
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 2))
    _ = builder.write_string(render_pixels(BODY, 6))
    _ = builder.write_string(render_pixels(SHADOW, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 8
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 8))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 9
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 8))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 10
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 8))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 11
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BODY, 4))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 12
    _ = builder.write_string(render_pixels(BORDER, 3))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 3))
    _ = builder.write_byte(NEWLINE)

    # 13
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_byte(NEWLINE)

    # 14
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 3))
    _ = builder.write_string(render_pixels(WING, 2))
    _ = builder.write_string(render_pixels(BODY, 3))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_byte(NEWLINE)

    # 15
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(WING, 2))
    _ = builder.write_string(render_pixels(BODY, 2))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 2))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_byte(NEWLINE)

    # 15
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 10))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(WING, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_byte(NEWLINE)

    # 15
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 10))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_byte(NEWLINE)

    # 16
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 8))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_byte(NEWLINE)

    # 17
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 8))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 1))
    _ = builder.write_byte(NEWLINE)

    # 18
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(SHADOW, 4))
    _ = builder.write_string(render_pixels(BODY, 1))
    _ = builder.write_string(render_pixels(SHADOW, 1))
    _ = builder.write_string(render_pixels(BORDER, 2))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # 19
    _ = builder.write_string(render_pixels(BACKGROUND, 3))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BODY, 3))
    _ = builder.write_string(render_pixels(SHADOW, 2))
    _ = builder.write_string(render_pixels(BODY, 3))
    _ = builder.write_string(render_pixels(BORDER, 1))
    _ = builder.write_string(render_pixels(BACKGROUND, 3))
    _ = builder.write_byte(NEWLINE)

    # 20
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_string(render_pixels(BORDER, 12))
    _ = builder.write_string(render_pixels(BACKGROUND, 2))
    _ = builder.write_byte(NEWLINE)

    # Name
    var border_style = mog.Style().padding(2, 4)
    var name_style = mog.Style().foreground(mog.Color(0xF25D94)).padding_left(2)
    var content = mog.join_horizontal(
        mog.center,
        str(builder),
        name_style.render(NAME)
    )

    print(border_style.render(content))

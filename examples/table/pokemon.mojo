# from external.string_dict import Dict
# from mog.border import rounded_border
# from mog.table import StyleFunction
# import mog
# import mog.table


# fn build_color_mapping() -> Dict[mog.Color]:
#     var type_colors = Dict[mog.Color]()
#     type_colors.put("Bug", mog.Color(0xD7FF87))
#     type_colors.put("Electric", mog.Color(0xFDFF90))
#     type_colors.put("Fire", mog.Color(0xFF7698))
#     type_colors.put("Flying", mog.Color(0xFF87D7))
#     type_colors.put("Grass", mog.Color(0x75FBAB))
#     type_colors.put("Ground", mog.Color(0xFF875F))
#     type_colors.put("Normal", mog.Color(0x929292))
#     type_colors.put("Poison", mog.Color(0x7D5AFC))
#     type_colors.put("Water", mog.Color(0x00E2C7))

#     return type_colors

# alias TYPE_COLORS = build_color_mapping()


# fn build_dim_color_mapping() -> Dict[mog.Color]:
#     var dim_type_colors = Dict[mog.Color]()
#     dim_type_colors.put("Bug", mog.Color(0x97AD64))
#     dim_type_colors.put("Electric", mog.Color(0xFCFF5F))
#     dim_type_colors.put("Fire", mog.Color(0xBA5F75))
#     dim_type_colors.put("Flying", mog.Color(0xC97AB2))
#     dim_type_colors.put("Grass", mog.Color(0x59B980))
#     dim_type_colors.put("Ground", mog.Color(0xC77252))
#     dim_type_colors.put("Normal", mog.Color(0x727272))
#     dim_type_colors.put("Poison", mog.Color(0x634BD0))
#     dim_type_colors.put("Water", mog.Color(0x439F8E))

#     return dim_type_colors


# alias DIM_TYPE_COLORS = build_dim_color_mapping()

# alias headers = List[String](
#         "#",
#         "Name",
#         "Type 1",
#         "Type 2",
#         "Official Rom."
#     )
# alias data = List[List[String]](
#     List[String]("1", "Bulbasaur", "Grass", "Poison", "Bulbasaur"),
#     List[String]("2", "Ivysaur", "Grass", "Poison", "Ivysaur"),
#     List[String]("3", "Venusaur", "Grass", "Poison", "Venusaur"),
#     List[String]("4", "Charmander", "Fire", "", "Hitokage"),
#     List[String]("5", "Charmeleon", "Fire", "", "Lizardo")
# )


# # fn make_style_func[data: List[List[String]]](
# #     header_style: mog.Style,
# #     selected_style: mog.Style,
# #     style: mog.Style,
# #     # data: List[List[String]] = data,
# #     # TYPE_COLORS: Dict[mog.Color] = TYPE_COLORS,
# #     # DIM_TYPE_COLORS: Dict[mog.Color] = DIM_TYPE_COLORS,
# # ) -> StyleFunction:
# #     @always_inline
# #     fn style_func(row: Int, col: Int) raises -> mog.Style:
# #         if row == 0:
# #             return header_style

# #         if data[row - 1][1] == "Pikachu":
# #             return selected_style

# #         var is_even = (row % 2 == 0)
# #         if col == 2 or col == 3:
# #             var colors = TYPE_COLORS
# #             if is_even:
# #                 colors = DIM_TYPE_COLORS

# #             var color = colors.get(data[row - 1][col], mog.Color(0xFFFFFF))
# #             var copy_style = style.foreground(color)
# #             return copy_style

# #         if is_even:
# #             var copy_style = style.foreground(mog.Color("245))
# #             return copy_style

# #         var copy_style = style.foreground(mog.Color("252))
# #         return copy_style
# #     return style_func


# fn main() raises:
#     # var style = mog.Style() \
#     # .padding_top(1) \
#     # .padding_right(1) \
#     # .padding_bottom(1) \
#     # .padding_left(1)

#     # var header_style = style \
#     # .foreground(mog.Color("252)) \
#     # .bold()

#     # var selected_style = style \
#     # .foreground(mog.Color(0x01BE85)) \
#     # .background(mog.Color(0x00432F))

#     @always_inline
#     fn capitalize_headers(data: List[String]) -> List[String]:
#         var upper = List[String]()
#         for element in data:
#             upper.append(element[].upper())

#         return upper

#     @always_inline
#     fn style_func(row: Int, col: Int) raises -> mog.Style:
#         var style = mog.Style() \
#         .padding_top(1) \
#         .padding_right(1) \
#         .padding_bottom(1) \
#         .padding_left(1)

#         var header_style = style \
#         .foreground(mog.Color("252)) \
#         .bold()

#         var selected_style = style \
#         .foreground(mog.Color(0x01BE85)) \
#         .background(mog.Color(0x00432F))

#         if row == 0:
#             return header_style

#         if data[row - 1][1] == "Pikachu":
#             return selected_style

#         var is_even = (row % 2 == 0)
#         if col == 2 or col == 3:
#             var colors = TYPE_COLORS
#             if is_even:
#                 colors = DIM_TYPE_COLORS

#             var color = colors.get(data[row - 1][col], mog.Color(0xFFFFFF))
#             var copy_style = style.foreground(color)
#             return copy_style

#         if is_even:
#             var copy_style = style.foreground(mog.Color("245))
#             return copy_style

#         var copy_style = style.foreground(mog.Color("252))
#         return copy_style

#     var border_style = mog.Style()
#     border_style = border_style.foreground(mog.Color("238))
#     var table = mog.new_table()
#     table.rows(data)
#     table.width = 100
#     table.border = rounded_border()
#     table.border_style = border_style
#     table.set_headers(capitalize_headers(headers))
#     table.style_function = style_func
#     print(table.render())

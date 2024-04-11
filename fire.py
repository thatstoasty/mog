import curses, random  # importing labs

screen = (
    curses.initscr()
)  # Initialize the library & Return a window object which represents the whole screen.
width = screen.getmaxyx()[
    1
]  # variabling the screen reso to be flexible to its screen max
height = screen.getmaxyx()[0]
size = width * height
char = [" ", ".", ":", "^", "*", "x", "s", "S", "#", "$"]  # init charactors
b = []  # init variable

curses.curs_set(0)  # Set the cursor state. visibility
curses.start_color()  # function to activate color mode with opt 8 diff colr
curses.init_pair(1, 0, 0)  # change defination of colours in pair
curses.init_pair(2, 1, 0)
curses.init_pair(3, 3, 0)
curses.init_pair(4, 4, 0)
screen.clear  # clear the screen
for i in range(size + width + 1):
    b.append(0)  # adds elements to the end of the list

# loop algo
while 1:
    for i in range(int(width / 9)):
        b[int((random.random() * width) + width * (height - 1))] = 65
    for i in range(size):
        b[i] = int((b[i] + b[i + 1] + b[i + width] + b[i + width + 1]) / 4)
        color = 4 if b[i] > 15 else (3 if b[i] > 9 else (2 if b[i] > 4 else 1))
        if i < size - 1:
            screen.addstr(
                int(
                    i / width
                ),  # displays a string at the current cursor location in the
                i % width,
                char[(9 if b[i] > 9 else b[i])],
                curses.color_pair(color) | curses.A_BOLD,
            )

    screen.refresh()  # refresh the window
    screen.timeout(30)  # max screen time  / sleep mode
    if screen.getch() != -1:
        break  # create a new window but you don't enable the keypad for it

# finally go back to the terminal/ending the window of curses
curses.endwin()

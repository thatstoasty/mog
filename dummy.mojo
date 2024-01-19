fn main() raises:
    let text: String = "Hello,\nworld!\n\n\n"
    let chunks = text.split("\n")

    print(chunks.size - 1)
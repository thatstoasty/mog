import os


fn main():
    if os.getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        print("This is Google Cloud Shell")
    else:
        print("This is not Google Cloud Shell")

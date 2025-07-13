#!/usr/bin/env python3
import termios
import tty

def get_cursor_position():
    with open('/dev/tty', 'wb') as tty_out:
        tty_out.write(b'\x1b[6n')  # Request cursor position
        tty_out.flush()

    with open('/dev/tty', 'rb') as tty_in:
        fd = tty_in.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            buf = b''
            while True:
                ch = tty_in.read(1)
                buf += ch
                if ch == b'R':
                    break
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    buf = buf.decode()
    # Expected: ESC [ row ; col R
    if buf.startswith('\x1b[') and buf.endswith('R'):
        pos = buf[2:-1]
        row, col = pos.split(';')
        print(row, col)
    else:
        print("Failed")
        exit(1)

if __name__ == '__main__':
    get_cursor_position()

package scal

import "core:mem"
import "core:unicode"
import "base:runtime"
import "core:sync/chan"
import "core:sync"
import "core:thread"
import "core:os"
import "core:strconv"
import "core:fmt"
import "core:strings"
import t "shared:termcl"
import term "shared:termcl/term"
import "core:time"

input_proc :: proc(thr: ^thread.Thread) {
    channel := cast(^Inp_Channel) thr.data
    

    buf: [1024]byte
    parse_buf: [dynamic]byte
    defer delete(parse_buf)

    for {
        n, err := os.read(os.stdin, buf[:])
        if err != .NONE || n <= 0 { continue }

        append(&parse_buf, ..buf[:n])

        for len(parse_buf) > 0 {
            input, consumed, ok := parse_input(parse_buf[:])
            if ok {
                
                chan.send(channel^, input)

                remaining := len(parse_buf) - consumed
                if remaining > 0 {
                    // Shift remaining bytes to the front (they may overlap, so use mem.copy)
                    mem.copy(rawptr(&parse_buf[0]), rawptr(&parse_buf[consumed]), remaining)
                }
                resize(&parse_buf, remaining) // truncate to the new length
                //new_len := len(parse_buf)
                //mem.copy_non_overlapping(rawptr(&parse_buf[0]), rawptr(&parse_buf[consumed-1]), new_len * size_of(byte))
                //resize(&parse_buf, new_len)
            } else {
                break // partial sequence, wait for more bytes
            }
        }
    }
}

// Manual parser for raw bytes into t.Input. Returns consumed bytes and ok if complete event parsed.
parse_input :: proc(data: []byte) -> (input: t.Input, consumed: int, ok: bool) {
    if len(data) == 0 { return }

    b0 := data[0]

    if b0 != 27 { // Plain ASCII or control
        r := rune(b0)
        key := rune_to_key(r)
        mod := t.Mod.None

        if b0 < 32 { // Control codes
            switch b0 {
            case 1..=26: 
                key = t.Key.A + t.Key(b0 - 1)
                mod = .Ctrl
            case 8: key = .Backspace
            case 9: key = .Tab
            case 13: key = .Enter
            case 27: key = .Escape // single ESC
            case 32: key = .Space
            case 127: key = .Delete // common for backspace in some terms
            case: return {}, 1, false // skip unknown
            }
        } else if unicode.is_upper(r) {
            mod = .Shift
        }

        if key == .None { return {}, 1, false } // unknown, consume to avoid loop

        input = t.Keyboard_Input{mod = mod, key = key}
        consumed = 1
        ok = true
        return
    }

    // ESC sequences
    if len(data) < 2 { return } // partial

    b1 := data[1]

    if b1 != '[' { // Alt + key
        r := rune(b1)
        key := rune_to_key(r)
        mod := t.Mod.Alt
        if unicode.is_upper(r) { mod |= .Shift }

        if key == .None { return {}, 2, false }

        input = t.Keyboard_Input{mod = mod, key = key}
        consumed = 2
        ok = true
        return
    }

    // CSI: ESC [
    if len(data) < 3 { return } // partial

    params: [dynamic]int
    defer delete(params)
    i := 2
    num := 0
    has_param := false

    for i < len(data) {
        b := data[i]
        if b >= '0' && b <= '9' {
            num = num * 10 + int(b - '0')
            has_param = true
            i += 1
        } else if b == ';' {
            append(&params, num)
            num = 0
            i += 1
        } else if b >= 'A' && b <= '~' { // final byte
            append(&params, num) // last param
            break
        } else {
            return // invalid sequence
        }
    }

    if i >= len(data) { return } // no final

    final := data[i]
    consumed = i + 1

    // Keyboard CSI
    key := t.Key.None
    mod := t.Mod.None

    if len(params) >= 1 && params[0] > 1 { // some terms use param[0] for mod, but often param[1]
        m := params[len(params) - 1] if len(params) > 1 else params[0] // last param often mod for special keys
        if m & 2 != 0 { mod |= .Shift }
        if m & 3 != 0 { mod |= .Alt } // 3 = shift+alt, etc.
        if m & 5 != 0 { mod |= .Ctrl }
        // approximate; adjust for your terminal
    }

    switch final {
    case 'A': key = .Arrow_Up
    case 'B': key = .Arrow_Down
    case 'C': key = .Arrow_Right
    case 'D': key = .Arrow_Left
    case 'H': key = .Home
    case 'F': key = .End
    case 'P': key = .F1
    case 'Q': key = .F2
    case 'R': key = .F3
    case 'S': key = .F4
    case '~': // tilde-terminated, e.g., [5~
        if len(params) >= 1 {
            switch params[0] {
            case 2: key = .Insert
            case 3: key = .Delete
            case 5: key = .Page_Up
            case 6: key = .Page_Down
            case 11: key = .F1
            case 12: key = .F2
            case 13: key = .F3
            case 14: key = .F4
            case 15: key = .F5
            case 17: key = .F6
            case 18: key = .F7
            case 19: key = .F8
            case 20: key = .F9
            case 21: key = .F10
            case 23: key = .F11
            case 24: key = .F12
            }
        }
    // Add more finals as needed (e.g., 'Z' for shift-tab)
    }

    if key == .None { return }

    input = t.Keyboard_Input{mod = mod, key = key}
    ok = true
    return
}

// Helper to map rune to t.Key (expand as needed for your use case)
rune_to_key :: proc(r: rune) -> t.Key {
    ru := unicode.to_upper(r) // for letters
    switch ru {
    case 'A': return .A
    case 'B': return .B
    case 'C': return .C
    case 'D': return .D
    case 'E': return .E
    case 'F': return .F
    case 'G': return .G
    case 'H': return .H
    case 'I': return .I
    case 'J': return .J
    case 'K': return .K
    case 'L': return .L
    case 'M': return .M
    case 'N': return .N
    case 'O': return .O
    case 'P': return .P
    case 'Q': return .Q
    case 'R': return .R
    case 'S': return .S
    case 'T': return .T
    case 'U': return .U
    case 'V': return .V
    case 'W': return .W
    case 'X': return .X
    case 'Y': return .Y
    case 'Z': return .Z
    case '0': return .Num_0
    case '1': return .Num_1
    case '2': return .Num_2
    case '3': return .Num_3
    case '4': return .Num_4
    case '5': return .Num_5
    case '6': return .Num_6
    case '7': return .Num_7
    case '8': return .Num_8
    case '9': return .Num_9
    case '-': return .Minus
    case '+': return .Plus
    case '=': return .Equal
    case '(': return .Open_Paren
    case ')': return .Close_Paren
    case '{': return .Open_Curly_Bracket
    case '}': return .Close_Curly_Bracket
    case '[': return .Open_Square_Bracket
    case ']': return .Close_Square_Bracket
    case ':': return .Colon
    case ';': return .Semicolon
    case '/': return .Slash
    case '\\': return .Backslash
    case '\'': return .Single_Quote
    case '"': return .Double_Quote
    case '.': return .Period
    case '*': return .Asterisk
    case '`': return .Backtick
    case ' ': return .Space
    case '$': return .Dollar
    case '!': return .Exclamation
    case '#': return .Hash
    case '%': return .Percent
    case '&': return .Ampersand
    case '_': return .Underscore
    case '^': return .Caret
    case ',': return .Comma
    case '|': return .Pipe
    case '@': return .At
    case '~': return .Tilde
    case '<': return .Less_Than
    case '>': return .Greater_Than
    case '?': return .Question_Mark
    case: return .None
    }
}

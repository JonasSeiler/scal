package main

import "core:os"
import "core:strconv"
import "core:fmt"
import "core:strings"
import t "shared:termcl"
import term "shared:termcl/term"
import "core:time"

fill_window :: proc(s: ^t.Window) {
    ws := t.get_window_size(s)
    for i in 0..<ws.h*ws.w {
        t.write(s, " ")
    }
}

render_months :: proc(s: ^t.Window) {
    t.reset_styles(s)
    t.set_text_style(s, {.Bold})
    fill_window(s)
    months :[]string= {"Jan.", "Feb.", "Mar.", "Apr.", "May", "June", "July", "Aug.", "Sept", "Oct.", "Nov.", "Dec."}
    for i in 0..<uint(len(months)) {
        t.move_cursor(s, 1+i*2, 2)
        t.write(s, months[i])
    }
    ts := t.get_window_size(s)
    t.move_cursor(s, 6, 8)
    for i in 0..<ts.h {
        t.move_cursor(s, 6+i, 8)
        t.write(s, "│")
    }
}

render_year :: proc(s: ^t.Window, y : int) {
    t.reset_styles(s)
    t.set_text_style(s, {.Bold})
    t.move_cursor(s, 25, 0)
    t.write(s, "────────┤")
    calc_cursor(s, 1, 2)
    t.write(s, fmt.tprint(y))
}

render_boxes :: proc(s: ^t.Screen) {
    t.reset_styles(s)
    ts := t.get_term_size()
    t.move_cursor(s, 6, 8)
    for i in 0..<ts.h {
        t.move_cursor(s, 6+i, 8)
        t.write(s, "│")
    }
}

calc_cursor :: proc(s: ^t.Window, y: int, x: int) {
    p := t.get_cursor_position(s)
    t.move_cursor(s, uint(int(p.y) + y), uint(int(p.x) + x))
}

wd_int :: proc(t : time.Time) -> uint {
    d := time.weekday(t)
    switch d {
    case .Monday: return 1
    case .Tuesday: return 2
    case .Wednesday: return 3
    case .Thursday: return 4
    case .Friday: return 5
    case .Saturday: return 6
    case .Sunday: return 7
    }
    return 0
}

m_int :: proc(m : time.Month) -> int {
    switch  m {
        case .January: return 1
        case .February: return 2
        case .March: return 3
        case .April: return 4 
        case .May: return 5
        case .June: return 6 
        case .July: return 7
        case .August: return 8
        case .September: return 9
        case .October: return 10
        case .November: return 11
        case .December: return 12
    }
    return 1
}

m_len :: proc(y : int, m : time.Month) -> uint {
    switch  m {
        case .January: return 31
        case .February: 
            if time.is_leap_year(y) do return 29
            else do return 28
        case .March: return 31
        case .April: return 30 
        case .May: return 31
        case .June: return 30 
        case .July: return 31
        case .August: return 31
        case .September: return 30
        case .October: return 31
        case .November: return 30
        case .December: return 31
    }
    return 0
}

render_days :: proc(s: ^t.Window, y: int, m: time.Month) {
    t.reset_styles(s)
    t.move_cursor(s, 2, 1)
    //maybe make the array dynamic at some point
    mi := m_int(m)
    now := time.datetime_to_time(y, mi, 1, 12, 0, 0)

    days : [37]uint
    i :uint= 0
    for ; i<wd_int(now); i+=1 {
        days[i] = 0
    }
    i-=1
    ml := m_len(y, m)
    for j:uint=1; j<=ml; j+=1 {
        days[i+j-1] = j
    }
    for i in 1..=uint(len(days)) {
        if i % 7 == 1 && i > 1 {
            t.move_cursor(s, t.get_cursor_position(s).y, 0)
            calc_cursor(s, 2, 1)
        }
        if days[i-1] < 10 do t.write(s, " ")
        if days[i-1] == 0 {
            t.write(s, " ")
        } else {
            t.write(s, fmt.tprint(days[i-1]))
        }
        calc_cursor(s, 0, 2)
    }
}

hl_day :: proc(s: ^t.Window, y, d : int, m : time.Month) {
    t.reset_styles(s)
    t.set_color_style(s, .Black, .White)
    t.set_text_style(s, {.Bold})
    t.move_cursor(s, 2, 1)
    mi := m_int(m)
    first := time.datetime_to_time(y, mi, 1, 12, 0, 0)
    offset := wd_int(first)-2
    col : int
    row : int
    if(d+int(offset) < 7) {
        row = 4*((d+int(offset)))
    }else {
        rev := 7-offset
        col = 2*((d+int(offset))/7)
        row = 4*((d-int(rev)) % 7)
    }
    calc_cursor(s, col, row)
    if d < 10 do t.write(s, " ")
        t.write(s, fmt.tprint(d))

}

render_wd :: proc(s: ^t.Window) {
    t.reset_styles(s)
    t.set_text_style(s, {.Bold})
    fill_window(s)
    wd : []string = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
    t.move_cursor(s, 0, 1)
    for i in 0..<uint(len(wd)) {
        t.write(s, wd[i])
        calc_cursor(s, 0, 2)
    }
    size := t.get_window_size(s)
    t.move_cursor(s, 1, 0)
    for i in 0..<size.w-1 {
        t.write(s, "─")
    }

}

render_title :: proc (s: ^t.Window) {
    t.reset_styles(s)
    fill_window(s)
    t.set_color_style(s, .Red, nil)
    t.set_text_style(s, {.Bold})
    t.move_cursor(s, 0, 0)
    t.write(s, "        ____      _")
    t.move_cursor(s, 1, 0)
    t.write(s, "   ___ / ___|__ _| |")
    t.move_cursor(s, 2, 0)
    t.write(s, "  / __| |   / _` | |")
    t.move_cursor(s, 3, 0)
    t.write(s, "  \\__ \\ |__| (_| | |")
    t.move_cursor(s, 4, 0)
    t.write(s, "  |___/\\____\\__,_|_|")
    ts := t.get_window_size(s)

    t.reset_styles(s)
    t.move_cursor(s, 6, 0)
    for i in 0..<ts.w-1 {
        t.write(s, "─")
    }
    t.move_cursor(s, 6, 8)
    t.write(s, "┬")
}

inc_m :: proc(m: time.Month, y : int) -> (time.Month, int) {
    switch  m {
        case .January: return .February, y
        case .February: return .March, y
        case .March: return .April, y
        case .April: return .May, y
        case .May: return .June, y
        case .June: return .July, y
        case .July: return .August, y
        case .August: return .September, y
        case .September: return .October, y
        case .October: return .November, y
        case .November: return .December, y
        case .December: return .January, y+1
    }
    return nil, 0
}
dec_m :: proc(m: time.Month, y : int) -> (time.Month, int) {
    switch  m {
        case .January: return .December, y-1
        case .February: return .January, y
        case .March: return .February, y
        case .April: return .March, y
        case .May: return .April, y
        case .June: return .May, y
        case .July: return .June, y
        case .August: return .July, y
        case .September: return .August, y
        case .October: return .September, y
        case .November: return .October, y
        case .December: return .November, y
    }
    return nil, 0
}

hl_month :: proc(s: ^t.Window, m: time.Month) {
    t.reset_styles(s)
    t.set_color_style(s, .Black, .White)
    t.set_text_style(s, {.Bold})
    switch  m {
        case .January:
            t.move_cursor(s, 1, 2)
            t.write(s, "Jan.")
        case .February:
            t.move_cursor(s, 3, 2)
            t.write(s, "Feb.")
        case .March:
            t.move_cursor(s, 5, 2)
            t.write(s, "Mar.")
        case .April:
            t.move_cursor(s, 7, 2)
            t.write(s, "Apr.")
        case .May:
            t.move_cursor(s, 9, 2)
            t.write(s, "May")
        case .June:
            t.move_cursor(s, 11, 2)
            t.write(s, "June")
        case .July:
            t.move_cursor(s, 13, 2)
            t.write(s, "July")
        case .August:
            t.move_cursor(s, 15, 2)
            t.write(s, "Aug.")
        case .September:
            t.move_cursor(s, 17, 2)
            t.write(s, "Sep.")
        case .October:
            t.move_cursor(s, 19, 2)
            t.write(s, "Oct.")
        case .November:
            t.move_cursor(s, 21, 2)
            t.write(s, "Nov.")
        case .December:
            t.move_cursor(s, 23, 2)
            t.write(s, "Dec.")
    }
}

menu :: enum {
   y = 0,
   m = 1,
   d = 2
}

main :: proc() {

    y_flag, m_flag, d_flag := time.date(time.now())
    s := t.init_screen(term.VTABLE, context.allocator)
    defer t.destroy_screen(&s)
    t.set_term_mode(&s, .Raw)
    c_menu := menu.m
    t_size := t.get_term_size()
    title := t.init_window(0, 0, 7, nil)
    dw := t.init_window(8, 10, 32, 29)
    side_bar :=t.init_window(7, 0, t_size.h-6, 9)
    defer t.destroy_window(&dw)
    defer t.destroy_window(&title)
    defer t.destroy_window(&side_bar)

    main_loop: for {
        t.clear(&s, .Everything)
        defer t.blit(&dw)
        defer t.blit(&title)
        defer t.blit(&side_bar)
        defer t.reset_styles(&s)
        t.hide_cursor(true)

        render_months(&side_bar)
        hl_month(&side_bar, m_flag)
        render_year(&side_bar, y_flag)
        render_title(&title)
        render_wd(&dw)
        render_days(&dw, y_flag, m_flag)
        hl_day(&dw,y_flag, d_flag, m_flag)

        inp, i_ok := t.read(&s).(t.Keyboard_Input)
        if i_ok do #partial switch inp.key {
        // movement keys
        case .J:
            if c_menu == .m do m_flag, y_flag = inc_m(m_flag, y_flag)
            else if c_menu == .y do if y_flag > 1700 do y_flag -= 1
            else if c_menu == .d {
                if d_flag+7<=int(m_len(y_flag, m_flag)) do d_flag += 7
            }
        case .K:
            if c_menu == .m do m_flag, y_flag= dec_m(m_flag, y_flag)
            else if c_menu == .y do if y_flag < 2200 do y_flag += 1
            else if c_menu == .d {
                if d_flag-7>0 do d_flag -= 7
            }
        case .L:
            if c_menu == .d do if(d_flag<int(m_len(y_flag, m_flag))) do d_flag += 1
        case .H:
            if c_menu == .d do if(d_flag>1) do d_flag -= 1

        // change mod keys
        case .Escape: 
            #partial switch c_menu {
                case .d:
                    c_menu = .m
                case .m:
                    c_menu = .y
            }
        case .Enter: 
            #partial switch c_menu {
                case .m:
                    c_menu = .d
                case .y:
                    c_menu = .m
             }
        case .M:

        case .D:

        case .Y:

        case .A:
        
        // command keys
        case .Q: break main_loop

        case .I:
            desc := os.Process_Desc {
                command = []string{"tmux", "split", "nvim", "./"},
                stdin = os.stdin,
                stdout = os.stdout, 
                stderr = os.stderr
            }
            process, start_err := os.process_start(desc)           
            if start_err != nil {
                return
            }
            state, wait_err := os.process_wait(process)
            if wait_err != nil {
                return 
            }
            clear := os.Process_Desc {
                command = []string{"clear"},
                stdin = os.stdin,
                stdout = os.stdout, 
                stderr = os.stderr
            }
        //case .M:

        case .C:



        }
    }
    
    

}

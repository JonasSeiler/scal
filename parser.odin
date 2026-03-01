package scal

import "core:strconv"
import "core:fmt"
import "core:os"
import "core:time"
import "core:strings"

flags :: struct {
    t1 : int, 
    m1 : int,
    t2 : int,
    m2 : int,
    tp : bool,
    rep : repeat,
}

repeat :: enum {
    none = 0,
    daily = 1,
    weekly = 2,
    monthly =3,
    anually = 4,
}



build_file_name :: proc(y : int, m : time.Month, d : int) -> string {
    return fmt.aprintf("%d-%2d-%2d.scal", y ,m_int(m), d)
} 

smart_split :: proc(h, w : uint, f : string) -> os.Process_Desc {
    desc : os.Process_Desc

    desc.command = []string{"tmux", "split-window", "-h", "nvim", fmt.aprintf("./%s", f)}
    desc.stdin = os.stdin
    desc.stdout = os.stdout
    desc.stderr = os.stderr

    if h > w/2 do desc.command[2] = "-v"

    return desc
}

start_editor :: proc(desc : os.Process_Desc) {
    process, start_err := os.process_start(desc)           
            if start_err != nil {
                return
            }
            state, wait_err := os.process_wait(process)
            if wait_err != nil {
                return 
            }
}

fetch_file :: proc(file : string) -> ([]string, bool) {
    
    data, read_ok := os.read_entire_file(file, context.allocator)
    if read_ok != nil {
        return nil,false
    }

    defer delete(data, context.allocator)

    lines_dyn := make([dynamic]string, context.allocator)

    it := string(data)
    for line in strings.split_lines_iterator(&it) {
        line_copy := strings.clone(line, context.allocator)
        append(&lines_dyn, line_copy)
    }
    return lines_dyn[:], true
}

write_flags :: proc(f_name : string, args : flags) {
    s : string
    if args.tp == true {
        s = fmt.aprintf("# -t %i:%i", args.t1, args.m1) 
    } else {
        s = fmt.aprintf("# -tr %i:%i %i:%i", args.t1, args.m1, args.t2, args.m2) 
    }
    switch args.rep {
        case .none: s = fmt.aprintf("%s \n", s)
        case .daily: s = fmt.aprintf("%s -dl\n", s)
        case .weekly: s = fmt.aprintf("%s -wl\n", s)
        case .monthly: s = fmt.aprintf("%s -ml\n", s)
        case .anually: s = fmt.aprintf("%s -al\n", s)
    }


    file, o_err := os.open(f_name, {.Append, .Write, .Create}, {.Read_User, .Write_User, .Read_Group, .Write_Group, .Read_Other, .Write_Other })
    if o_err != os.General_Error.None {
        return
    }
    defer os.close(file)
    
    bw, w_err := os.write_string(file, s)
    if w_err != os.General_Error.None {
        return 
    }
    
}

find_appointments :: proc() {}

appointment :: struct { 
    args : flags, 
    body : [dynamic]string
} 


split_file :: proc(file : []string) -> []appointment {
    apps := make([dynamic]appointment, context.allocator)
    curr : ^appointment = nil
    for line in file {
        if strings.starts_with(line, "# ") {
            tapps := appointment {
                args = read_flags(line),
                body = make([dynamic]string)
            }
            append(&apps, tapps)
            curr = &apps[len(apps)-1]
        } else if curr != nil {
            append(&curr.body, line)
        }
    }
    return apps[:]
}

read_flags :: proc(s : string) -> flags {
    return {}
}

sort_appointments :: proc() {}

package ocli

import "core:fmt"
import "core:testing"
import "core:os"
import "core:strings"
import "core:slice"

// @private
app_options:[dynamic]Ocli_Option
app_positional_arguments:[dynamic]Ocli_Positional_Argument
app_arguments:[dynamic]Ocli_Argument

Ocli_Option :: struct{
    name:string,
    short_name:string,
    help:string,
}

Ocli_Positional_Argument :: struct{
    name:string,
    help:string,
    index:int,
}

Ocli_Argument :: struct{
    name:string,
    short_name:string,
    help:string,
    required:bool,
}


register_option :: proc(
    name:string, 
    short_name:string = "", 
    help:string = ""
){
    option := Ocli_Option{
        name = name,
        short_name = short_name,
        help = help,
    }
    append(&app_options, option)
}

register_positional_argument :: proc(
    name:string,
    index:int,
    help:string = "",
){
    argument := Ocli_Positional_Argument{
        name = name,
        help = help,
        index = index,
    }
    append(&app_positional_arguments, argument)
}

register_argument :: proc(
    name:string,
    short_name:string = "",
    help:string = "",
    required:bool = false,
){
    option_argument := Ocli_Argument{
        name = name,
        short_name = short_name,
        help = help,
        required = required,
    }
    append(&app_arguments, option_argument)
}

parse_arguments :: proc() -> map[string]any{
    defer {
        delete(app_options)
        delete(app_arguments)
        delete(app_positional_arguments)
    }
    //  options => option_argument => positional_argument
    // TODO problème si args -- ou - sont mentionné dans le cli sans rien
    parsed_args := map[string]any{}
    os_args:[dynamic]string = slice.to_dynamic(os.args[1:])
    indexes_to_rm:[dynamic]int = make([dynamic]int, 0,len(os.args))
    defer delete(os_args)
    defer delete(indexes_to_rm)

    for option in app_options{
        name_option, _ := strings.concatenate([]string{"--", option.name})
        short_option, _ := strings.concatenate([]string{"-", option.short_name})
        for arg, i in os_args{
            if arg == name_option || arg == short_option{
                parsed_args[option.name] = true
                append(&indexes_to_rm, i)
            }
            else{
                parsed_args[option.name] = false
            }
        }
    }
    for i in indexes_to_rm{
        ordered_remove(&os_args, i)
    }
    clear(&indexes_to_rm)

    //  argument => positional_argument
    for arg in app_arguments{
        name_arg, _ := strings.concatenate([]string{"--", arg.name})
        short_arg, _ := strings.concatenate([]string{"-", arg.short_name})

        for cli_arg, i in os_args{
            if cli_arg == name_arg || cli_arg == short_arg{
                if os_args[i+1][0] == '-'{

                }
            }
            else if arg.required{
                
            }
            else{

            }
        }
    }
    return parsed_args
}




// TESTS




@(test)
test_register_option :: proc(t:^testing.T){
    testing.expect(t, app_options == nil)
    register_option("test", "t")
    test_option := Ocli_Option{
        name = "test",
        short_name = "t",
        help = "",
    }
    testing.expect(t, app_options[0] == test_option)
}

@(test)
test_register_optional :: proc(t:^testing.T){
    testing.expect(t, app_arguments == nil)
    register_argument("test", "t", "help")
    test_optional_arg := Ocli_Argument{
        name = "test",
        short_name = "t",
        help = "help",
        required = false,
    }
    testing.expect(t, app_arguments[0] == test_optional_arg)
}

@(test)
test_register_positional_argument :: proc(t:^testing.T){
    testing.expect(t, app_positional_arguments == nil)
    register_positional_argument("test", 1, "help")
    test_pos_arg := Ocli_Positional_Argument{
        name = "test",
        index = 1,
        help = "help",
    }
    testing.expect(t, app_positional_arguments[0] == test_pos_arg)
}

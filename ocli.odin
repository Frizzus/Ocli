package ocli

import "core:fmt"
import "core:testing"
import "core:os"
import "core:strings"
import "core:slice"
import "core:mem"

// @private
app_options:[dynamic]OcliOption
app_positional_arguments:[dynamic]OcliPositionalArgument
app_arguments:[dynamic]OcliArgument

OcliOption :: struct{
    name:string,
    short_name:string,
    help:string,
}

OcliPositionalArgument :: struct{
    name:string,
    help:string,
    index:int,
}

OcliArgument :: struct{
    name:string,
    short_name:string,
    help:string,
    required:bool,
}

MissingArgumentError :: struct{
    line:int,
    column:int,
    cli_index:int,
}

ParseError :: union{
    mem.Allocator_Error,
    MissingArgumentError,
}


register_option :: proc(
    name:string, 
    short_name:string = "", 
    help:string = ""
){
    option := OcliOption{
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
    argument := OcliPositionalArgument{
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
    option_argument := OcliArgument{
        name = name,
        short_name = short_name,
        help = help,
        required = required,
    }
    append(&app_arguments, option_argument)
}

parse_arguments :: proc() -> (parsed:map[string]any, err:ParseError){
    defer {
        delete(app_options)
        delete(app_arguments)
        delete(app_positional_arguments)
    }
    //  options => option_argument => positional_argument
    // TODO problème si args -- ou - sont mentionné dans le cli sans rien
    parsed_args := map[string]any{}
    os_args:[dynamic]string = slice.to_dynamic(os.args[1:]) or_return
    indexes_to_rm:[dynamic]int = make([dynamic]int, 0,len(os.args))
    defer delete(os_args)
    defer delete(indexes_to_rm)

    for option in app_options{
        name_option := strings.concatenate([]string{"--", option.name}) or_return
        short_option := strings.concatenate([]string{"-", option.short_name}) or_return
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
        name_arg := strings.concatenate([]string{"--", arg.name}) or_return
        short_arg := strings.concatenate([]string{"-", arg.short_name}) or_return

        for cli_arg, i in os_args{
            if cli_arg == name_arg || cli_arg == short_arg{
                if i+1 > len(os_args){
                    return nil, MissingArgumentError{
                        line = 125,
                        column = 20,
                        cli_index = i+1,
                    }
                }
                
            }
            else if arg.required{
                
            }
            else{

            }
        }
    }
    return parsed_args, nil
}




// TESTS




@(test)
test_register_option :: proc(t:^testing.T){
    testing.expect(t, app_options == nil)
    register_option("test", "t")
    test_option := OcliOption{
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
    test_optional_arg := OcliArgument{
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
    test_pos_arg := OcliPositionalArgument{
        name = "test",
        index = 1,
        help = "help",
    }
    testing.expect(t, app_positional_arguments[0] == test_pos_arg)
}

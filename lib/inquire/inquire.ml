exception Interrupted_by_user = Exn.Interrupted_by_user

module Style = Style

let confirm = Prompt_confirm.prompt

let input = Prompt_input.prompt

let password = Prompt_password.prompt

let raw_select = Prompt_raw_select.prompt

let select = Prompt_select.prompt

let set_exit_on_user_interrupt v = Utils.exit_on_user_interrupt := v

module Make (M : Impl.M) = struct
  let confirm ?default message =
    Confirm.prompt message ?default ~impl:(module M)

  let password ?validate message =
    Password.prompt message ?validate ~impl:(module M)

  let input ?validate ?default message =
    Input.prompt message ?validate ?default ~impl:(module M)

  let raw_select ?default ~options message =
    Raw_select.prompt message ?default ~options ~impl:(module M)

  let select ?default ~options message =
    Select.prompt message ?default ~options ~impl:(module M)
end

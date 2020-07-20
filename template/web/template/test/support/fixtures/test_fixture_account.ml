open Demo

module User = struct
  module Name = struct
    let count = ref 0

    let count_mutex = Mutex.create ()

    let fixture ?v () =
      Mutex.lock count_mutex;
      let v =
        Account.User.Name.of_string
          (Option.value v ~default:("user-name-" ^ string_of_int !count))
        |> Result.get_ok
      in
      count := !count + 1;
      Mutex.unlock count_mutex;
      v
  end

  let name_fixture = Name.fixture

  let user_fixture ?user ?name () =
    let open Lwt.Syntax in
    let* user =
      match user with
      | Some user ->
        Lwt.return user
      | None ->
        Test_fixture_account.user_fixture ()
    in
    let name = Option.value name ~default:(name_fixture ()) in
    let+ d = User.create_user ~user ~name () in
    Result.get_ok d
end

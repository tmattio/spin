module Name = struct
  open Std.Result.Syntax

  type t = string [@@deriving show, eq]

  let validate s =
    if String.length s > 60 then
      Error (`Validation_error "The name must contain at most 60 characters.")
    else
      Ok s

  let of_string s =
    let+ _result = validate s in
    s

  let to_string s = s

  let t =
    Caqti_type.(
      custom
        ~encode:(fun x ->
          of_string x
          |> Result.map_error (function `Validation_error err -> err))
        ~decode:(fun x -> Ok (to_string x))
        string)
end

type t =
  { id : int
  ; name : Name.t
  ; created_at : Ptime.t
  ; updated_at : Ptime.t
  }
[@@deriving show, eq]

let get_all () =
  let request =
    [%rapper
      get_many
        {sql|
        SELECT
          @int{id},
          @Name{name}, 
          @ptime{created_at}, 
          @ptime{updated_at}
        FROM users
        |sql}
        record_out]
  in
  Repo.query (fun c -> request () c)

let get_by_id id =
  let request =
    [%rapper
      get_opt
        {sql|
        SELECT
          @int{id},
          @Name{name}, 
          @ptime{created_at}, 
          @ptime{updated_at}
        FROM users
        WHERE id = %int{id}
        |sql}
        record_out]
  in
  Repo.query_opt (fun c -> request c ~id)

let create ~name () =
  let request =
    [%rapper
      get_one
        {sql| 
        INSERT INTO users (name)
        VALUES (%Name{name})
        RETURNING
          @int{id},
          @Name{name}, 
          @ptime{created_at}, 
          @ptime{updated_at}
        |sql}
        record_out]
  in
  Repo.query (fun c -> request c ~name)

let update ?name t =
  let name = Option.value name ~default:t.name in
  let request =
    [%rapper
      get_one
        {sql|
        UPDATE users SET name = %Name{name}
        WHERE users.id = %int{id}
        RETURNING
          @int{id},
          @Name{name}, 
          @ptime{created_at}, 
          @ptime{updated_at}
        |sql}
        record_out]
  in
  Repo.query (fun c -> request c ~id:t.id ~name)

let delete t =
  let request =
    [%rapper
      execute
        {sql|
        DELETE FROM users
        WHERE users.id = %int{id}
        |sql}]
  in
  Repo.query (fun c -> request c ~id:t.id)

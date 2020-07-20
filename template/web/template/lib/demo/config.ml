let getenv e =
  try Sys.getenv e with
  | Not_found ->
    failwith
      (Printf.sprintf
         "The environment variable %s is required but is not set on your \
          system."
         e)

module Env_production = struct
  let database_host () = getenv "DEMO_DATABASE_HOST"

  let database_port () = getenv "DEMO_DATABASE_PORT" |> int_of_string

  let database_name () = getenv "DEMO_DATABASE_NAME"
end

module Env_development = struct
  let database_host () = "localhost"

  let database_port () = 5432

  let database_name () = "demo_dev"
end

module Env_test = struct
  let database_host () = "localhost"

  let database_port () = 5432

  let database_name () = "demo_test"
end

module type ENV = sig
  val database_host : unit -> string

  val database_port : unit -> int

  val database_name : unit -> string
end

let is_test =
  match Sys.getenv_opt "DEMO_ENV" with Some "test" -> true | _ -> false

let is_prod =
  match Sys.getenv_opt "DEMO_ENV" with
  | Some "prod" | Some "production" ->
    true
  | _ ->
    false

let is_dev = (not is_test) && not is_prod

let choose_env ~prod ~dev ~test =
  match Sys.getenv_opt "DEMO_ENV" with
  | Some "prod" | Some "production" ->
    prod
  | Some "dev" | Some "development" ->
    dev
  | Some "test" ->
    test
  | _ ->
    dev

let env =
  choose_env
    ~prod:(module Env_production : ENV)
    ~test:(module Env_test : ENV)
    ~dev:(module Env_development : ENV)

module Env = (val env)

let database_host =
  Sys.getenv_opt "DEMO_DATABASE_HOST"
  |> Option.value ~default:(Env.database_host ())

let database_port =
  Sys.getenv_opt "DEMO_DATABASE_PORT"
  |> Option.map int_of_string
  |> Option.value ~default:(Env.database_port ())

let database_name =
  Sys.getenv_opt "DEMO_DATABASE_NAME"
  |> Option.value ~default:(Env.database_name ())

let database_uri =
  Printf.sprintf
    "postgresql://%s:%i/%s"
    database_host
    database_port
    database_name

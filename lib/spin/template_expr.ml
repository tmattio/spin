open Dec_template

exception Invalid_expr of string

let rec eval ~context = function
  | Expr.Var name ->
    (match Hashtbl.find context name with
    | Some var ->
      Lwt.return var
    | None ->
      raise
        (Invalid_expr
           (Printf.sprintf "The context variable is missing: %s" name)))
  | Expr.Function fn ->
    eval_fn fn ~context
  | Expr.String s ->
    Lwt.return s

and eval_fn ~context =
  let open Lwt.Syntax in
  let eval = eval ~context in
  let to_bool = to_bool ~context in
  function
  | Expr.If (e1, e2, e3) ->
    let* e1 = to_bool e1 in
    if e1 then eval e2 else eval e3
  | Expr.Eq (e1, e2) ->
    let* e1 = eval e1 in
    let+ e2 = eval e2 in
    String.equal e1 e2 |> Bool.to_string
  | Expr.Neq (e1, e2) ->
    let* e1 = eval e1 in
    let+ e2 = eval e2 in
    (not (String.equal e1 e2)) |> Bool.to_string
  | Expr.Not e ->
    let+ e = to_bool e in
    (not e) |> Bool.to_string
  | Expr.Slugify e ->
    let+ e = eval e in
    Helpers.slugify e
  | Expr.Upper e ->
    let+ e = eval e in
    String.uppercase e
  | Expr.Lower e ->
    let+ e = eval e in
    String.lowercase e
  | Expr.Snake_case e ->
    let+ e = eval e in
    Helpers.snake_case e
  | Expr.Camel_case e ->
    let+ e = eval e in
    Helpers.camel_case e
  | Expr.Trim e ->
    let+ e = eval e in
    String.strip e
  | Expr.First_char e ->
    let+ e = eval e in
    String.prefix e 1
  | Expr.Last_char e ->
    let+ e = eval e in
    String.suffix e 1
  | Expr.Run (cmd, args) ->
    let* cmd = eval cmd in
    let* args = Spin_lwt.fold_left args ~f:eval in
    let+ p_out = Spin_lwt.exec cmd args in
    (match p_out.status with WEXITED 0 -> "false" | _ -> "true")
  | Expr.Concat l ->
    let+ l = Spin_lwt.fold_left l ~f:eval in
    String.concat l

and to_bool ~context expr =
  let open Lwt.Syntax in
  let+ e = eval expr ~context in
  try Bool.of_string e with
  | Invalid_expr _ as e ->
    raise e
  | _ ->
    raise (Invalid_expr "The expression cannot be evaluated to a boolean")

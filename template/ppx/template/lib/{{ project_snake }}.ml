open Ppxlib

module Builder = Ast_builder.Default

let expand ~loc ~path:_ (num : int) =
  let (module Builder) = Ast_builder.make loc in
  [%expr [%e Builder.eint num] + 5]

let name = "{{ project_snake }}"

let extension =
  Extension.declare
    name
    Extension.Context.expression
    (let open Ast_pattern in
    single_expr_payload (eint __))
    expand

let rule = Context_free.Rule.extension extension

let () = Driver.register_transformation name ~rules:[ rule ]
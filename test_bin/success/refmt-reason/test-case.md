```sh
$ spin new --ignore-config . _generated
...
$ ls _generated
file.ml
$ cat _generated/file.ml
let () = print_endline "Hello World"
```

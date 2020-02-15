open Alcotest;
open Spin;

let test_slugify = () => {
    let t = Jg_wrapper.slugify("My Project Name");
    check(string, "same string", "my-project-name", t);

    let t = Jg_wrapper.slugify("MyProjectName");
    check(string, "same string", "myprojectname", t);
}

let test_snake_case = () => {
    let t = Jg_wrapper.snake_case("MyProjectName");
    check(string, "same string", "my_project_name", t);

    let t = Jg_wrapper.snake_case("My Project Name");
    check(string, "same string", "my_project_name", t);

    let t = Jg_wrapper.snake_case("My-Project-Name");
    check(string, "same string", "my_project_name", t);
}

let test_camel_case = () => {
    let t = Jg_wrapper.camel_case("my_project_name");
    check(string, "same string", "MyProjectName", t);

    let t = Jg_wrapper.camel_case("my-project-name");
    check(string, "same string", "MyProjectName", t);
}

let suite = [
  ("convert string to slug format", `Quick, test_slugify),
  ("convert string to snake case format", `Quick, test_snake_case),
  ("convert string to camel case format", `Quick, test_camel_case),
];

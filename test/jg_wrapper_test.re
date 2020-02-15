open Test_framework;
open Spin;

describe("Test Jg_wrapper", ({test, describe, _}) => {
  test("slugify", ({expect, _}) => {
    let t = Jg_wrapper.slugify("My Project Name");
    expect.string(t).toEqual("my-project-name");

    let t = Jg_wrapper.slugify("MyProjectName");
    expect.string(t).toEqual("myprojectname");
  });

  test("snake_case", ({expect, _}) => {
    let t = Jg_wrapper.snake_case("MyProjectName");
    expect.string(t).toEqual("my_project_name");

    let t = Jg_wrapper.snake_case("My Project Name");
    expect.string(t).toEqual("my_project_name");

    let t = Jg_wrapper.snake_case("My-Project-Name");
    expect.string(t).toEqual("my_project_name");
  });

  test("camel_case", ({expect, _}) => {
    let t = Jg_wrapper.camel_case("my_project_name");
    expect.string(t).toEqual("MyProjectName");

    let t = Jg_wrapper.camel_case("my-project-name");
    expect.string(t).toEqual("MyProjectName");
  });
});

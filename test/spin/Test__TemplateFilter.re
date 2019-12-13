open TestFramework;
open Spin;

describe("Test TemplateFilter", ({test, describe, _}) => {
  test("slugify", ({expect, _}) => {
    let t = TemplateFilter.slugify("My Project Name");
    expect.string(t).toEqual("my-project-name");

    let t = TemplateFilter.slugify("MyProjectName");
    expect.string(t).toEqual("myprojectname");
  });

  test("snake_case", ({expect, _}) => {
    let t = TemplateFilter.snake_case("MyProjectName");
    expect.string(t).toEqual("my_project_name");
  });

  test("camel_case", ({expect, _}) => {
    let t = TemplateFilter.camel_case("my_project_name");
    expect.string(t).toEqual("MyProjectName");

    let t = TemplateFilter.camel_case("my-project-name");
    expect.string(t).toEqual("MyProjectName");
  });
});

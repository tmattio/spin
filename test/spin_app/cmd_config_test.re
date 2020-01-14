open Test_framework;

describe("Test Integration `spin config`", ({test, _}) => {
  test("Validate standard output", ({expect}) => {
    let output = Test_utils.run([|"config"|]);
    expect.string(output |> String.strip).toMatch("Hello World!");
  })
});

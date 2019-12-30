open Test_framework;

describe("SmokeTest Version", ({test, _}) => {
  test("Get version", ({expect}) => {
    let version = Test_utils.run([|"--version"|]);
    expect.string(version |> String.strip).toMatch("^\\d+.\\d+.\\d+$");
  })
});

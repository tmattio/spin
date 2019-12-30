open Test_framework;

describe("SmokeTest Version", ({test, _}) => {
  test("Get version", ({expect}) => {
    let version = Test_utils.run([|"--version"|]);
    let expected = expect.string(version |> String.strip);
    expected.toMatch("^\\d+.\\d+.\\d+$");
  })
});

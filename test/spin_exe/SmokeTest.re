open TestFramework;

describe("SmokeTest Version", ({test, _}) => {
  test("Get version", ({expect}) => {
    let version = run([|"--version"|]);
    expect.string(version |> String.strip).toMatch("^\\d+.\\d+.\\d+$");
  })
});

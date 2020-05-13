open Jest;
open Expect;
open ReactTestingLibrary;

describe("Home component", () => {
  test("renders without crashing", () => {
    let wrapper = render(<App />);

    Utils.act(() => ReasonReactRouter.push("/"));

    wrapper
    |> getByText(~matcher=`Str("Learn Reason React"))
    |> Webapi.Dom.Element.innerHTML
    |> expect
    |> toEqual("Learn Reason React");
  })
});

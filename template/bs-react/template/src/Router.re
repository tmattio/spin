let useRouter = () => ReasonReactRouter.useUrl()->Route.fromUrl;

let push = route => route->Route.toString->ReasonReactRouter.push;

module Link = {
  [@react.component]
  let make = (~route: Route.t', ~children) => {
    let location = route->Route.toString;

    <a
      href=location
      onClick={event =>
        if (!event->ReactEvent.Mouse.defaultPrevented
            && event->ReactEvent.Mouse.button == 0
            && !event->ReactEvent.Mouse.altKey
            && !event->ReactEvent.Mouse.ctrlKey
            && !event->ReactEvent.Mouse.metaKey
            && !event->ReactEvent.Mouse.shiftKey) {
          event->ReactEvent.Mouse.preventDefault;
          location->ReasonReactRouter.push;
        }
      }>
      children
    </a>;
  };
};

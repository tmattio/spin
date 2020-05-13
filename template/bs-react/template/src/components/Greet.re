{% if css_framework == 'None' -%}
module Styles = {
  open Css;

  let container = style([textAlign(center), marginTop(rem(3.))]);

  let text =
    style([
      fontSize(rem(1.875)),
      color(hex("1a202c")),
      marginBottom(rem(1.)),
    ]);

  let link =
    style([
      fontSize(rem(1.875)),
      textDecoration(`none),
      color(hex("4299e1")),
    ]);
};
{%- endif %}

[@react.component]
let make = (~name) => {
  <div className=
    {%- if css_framework == 'TailwindCSS' -%}
    "text-center mt-12"
    {%- else -%}
    Styles.container
    {%- endif %}>
    <p className=
    {%- if css_framework == 'TailwindCSS' -%}
    "text-3xl text-gray-900 mb-4"
    {%- else -%}
    Styles.text
    {%- endif %}>
      {React.string({j|👋 Welcome $name! You can edit me in |j})}
      <code> {React.string("src/components/Greet.re")} </code>
    </p>
    <a
      className=
    {%- if css_framework == 'TailwindCSS' -%}
    "text-3xl no-underline text-blue-500"
    {%- else -%}
    Styles.link
    {%- endif %}
      href="https://reasonml.github.io/reason-react/">
      {React.string("Learn Reason React")}
    </a>
  </div>;
};

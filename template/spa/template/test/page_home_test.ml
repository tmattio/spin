open! Incr_dom_testing
open {{ project_snake | capitalize }}

let%expect_test "can render home page" =
  let driver =
    Driver.create
      ~initial_model:Page_home.Model.empty
      ~initial_state:()
      ~sexp_of_model:Page_home.Model.sexp_of_t
      (module Page_home)
  in
  let module H = (val Helpers.make driver) in
  H.show_view ();
  [%expect
  {%- if css_framework == 'None' -%}
  {% raw -%}
    {|
    <div>
      <div class="greet__container">
        <p class="greet__welcome-message">
          👋 Welcome Visitor! You can edit me in
          <code>
      lib/components/greet.{% endraw %}{% if syntax == 'Reason' %}re{% else %}ml{% endif %}{% raw %} </code>
        </p>
        <p class="greet__text"> Here a simple counter example that you can look at to get started: </p>
        <div class="greet__button-container">
          <button type="button" class="greet__button" onclick={handler}> - </button>
          <span class="greet__button"> 0 </span>
          <button type="button" class="greet__button" onclick={handler}> + </button>
        </div>
        <div>
          <span class="greet__text">
            And here's a link to demonstrate navigation:
            <a href="/" onclick={handler}> Home </a>
          </span>
        </div>
      </div>
    </div>
|}
  {%- endraw %}
  {%- else -%}
  {% raw -%}
  {|
  <div>
    <div class="text-center mt-12">
      <p class="text-3xl text-gray-900 mb-4">
        👋 Welcome Visitor! You can edit me in
        <code>
    lib/components/greet.{% endraw %}{% if syntax == 'Reason' %}re{% else %}ml{% endif %}{% raw %} </code>
      </p>
      <p class="text-xl text-gray-900 mb-4"> Here a simple counter example that you can look at to get started: </p>
      <div class="space-x-6 mb-4">
        <button type="button" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500" onclick={handler}> - </button>
        <span class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500"> 0 </span>
        <button type="button" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500" onclick={handler}> + </button>
      </div>
      <div>
        <span class="text-xl text-gray-900 mb-4">
          And here's a link to demonstrate navigation:
          <a href="/" onclick={handler}> Home </a>
        </span>
      </div>
    </div>
  </div>
|}
  {%- endraw %}
  {%- endif %}];
  H.do_actions [ Page_home.Action.Greet_action Greet.Action.Increment ];
  H.perform_update ();
  H.show_model ();
  [%expect {| ((greet_model 1)) |}];
  H.show_view ();
  [%expect
  {%- if css_framework == 'None' -%}
  {% raw -%}
    {|
    <div>
      <div class="greet__container">
        <p class="greet__welcome-message">
          👋 Welcome Visitor! You can edit me in
          <code>
      lib/components/greet.{% endraw %}{% if syntax == 'Reason' %}re{% else %}ml{% endif %}{% raw %} </code>
        </p>
        <p class="greet__text"> Here a simple counter example that you can look at to get started: </p>
        <div class="greet__button-container">
          <button type="button" class="greet__button" onclick={handler}> - </button>
          <span class="greet__button"> 1 </span>
          <button type="button" class="greet__button" onclick={handler}> + </button>
        </div>
        <div>
          <span class="greet__text">
            And here's a link to demonstrate navigation:
            <a href="/" onclick={handler}> Home </a>
          </span>
        </div>
      </div>
    </div>
|}
  {%- endraw %}
  {%- else -%}
  {% raw -%}
  {|
  <div>
    <div class="text-center mt-12">
      <p class="text-3xl text-gray-900 mb-4">
        👋 Welcome Visitor! You can edit me in
        <code>
    lib/components/greet.{% endraw %}{% if syntax == 'Reason' %}re{% else %}ml{% endif %}{% raw %} </code>
      </p>
      <p class="text-xl text-gray-900 mb-4"> Here a simple counter example that you can look at to get started: </p>
      <div class="space-x-6 mb-4">
        <button type="button" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500" onclick={handler}> - </button>
        <span class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500"> 1 </span>
        <button type="button" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500" onclick={handler}> + </button>
      </div>
      <div>
        <span class="text-xl text-gray-900 mb-4">
          And here's a link to demonstrate navigation:
          <a href="/" onclick={handler}> Home </a>
        </span>
      </div>
    </div>
  </div>
|}
  {%- endraw %}
  {%- endif %}];

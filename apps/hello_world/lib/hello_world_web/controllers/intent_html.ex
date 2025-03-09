defmodule HelloWorldWeb.IntentHTML do
  use HelloWorldWeb, :html
  import Phoenix.Controller, only: [get_csrf_token: 0]
  embed_templates "intent_html/*"
end 
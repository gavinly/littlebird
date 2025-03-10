defmodule DeployHelloWeb.IntentHTML do
  use DeployHelloWeb, :html
  import Phoenix.Controller, only: [get_csrf_token: 0]
  embed_templates "intent_html/*"
end 
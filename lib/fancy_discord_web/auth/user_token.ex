defmodule FancyDiscordWeb.Auth.UserToken do
  alias Phoenix.Token
  alias FancyDiscordWeb.Endpoint
  @salt Application.fetch_env!(:fancy_discord, :user_token_salt)

  def sign(data, opts \\ []) do
    Token.sign(Endpoint, @salt, data, opts)
  end

  def verify(token, opts \\ []) do
    Token.verify(Endpoint, @salt, token, opts)
  end
end

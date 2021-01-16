defmodule FancyDiscordWeb.AuthorizationController do
  @moduledoc false
  use Pow.Extension.Phoenix.Controller.Base

  require Logger

  alias Plug.Conn
  alias Pow.Extension.Config, as: ExtensionConfig
  alias Pow.Plug, as: PowPlug
  alias PowAssent.{Phoenix.RegistrationController, Plug}
  alias PowEmailConfirmation.Phoenix.ControllerCallbacks, as: EmailConfirmationCallbacks

  plug :require_authenticated when action in [:delete]
  plug :assign_callback_url when action in [:new, :callback]
  plug :init_session when action in [:new, :callback]
  plug :assign_request_path when action in [:callback]
  plug :load_session_params when action in [:callback]
  plug :set_registration_option when action in [:callback]
  plug :load_user_by_invitation_token when action in [:callback]

  @spec process_new(Conn.t(), map()) :: {:ok, binary(), Conn.t()} | {:error, any(), Conn.t()}
  def process_new(conn, %{"provider" => provider}) do
    Plug.authorize_url(conn, provider, conn.assigns.callback_url)
  end

  @spec process_callback(Conn.t(), map()) :: {:ok, Conn.t()} | {:error, Conn.t()} | {:error, {atom(), map()} | map(), Conn.t()}
  def process_callback(conn, %{"provider" => provider} = params) do
    Plug.callback_upsert(conn, provider, params, conn.assigns.callback_url)
  end

  @spec respond_callback({:ok, Conn.t()} | {:error, Conn.t()} | {:error, {atom(), map()} | map(), Conn.t()}) :: Conn.t()
  def respond_callback({:ok, %{private: %{pow_assent_callback_state: {:ok, :create_user}}} = conn}) do
    trigger_registration_email_confirmation_controller_callback(conn, fn conn ->
      conn
      |> put_flash(:info, extension_messages(conn).user_has_been_created(conn))
      |> redirect(to: routes(conn).after_registration_path(conn))
    end)
  end
  def respond_callback({:ok, conn}) do
    trigger_session_email_confirmation_controller_callback(conn, fn conn ->
      conn
      |> put_flash(:info, extension_messages(conn).signed_in(conn))
      |> redirect(to: routes(conn).after_sign_in_path(conn))
    end)
  end
  def respond_callback({:error, %{private: %{pow_assent_callback_state: {:error, :strategy}, pow_assent_callback_error: error}} = conn}),
      do: handle_strategy_error(conn, error)
  def respond_callback({:error, %{private: %{pow_assent_callback_error: {:bound_to_different_user, _changeset}}} = conn}) do
    conn
    |> put_flash(:error, extension_messages(conn).account_already_bound_to_other_user(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end
  def respond_callback({:error, %{private: %{pow_assent_callback_error: {:invalid_user_id_field, changeset}}} = conn}) do
    trigger_registration_email_confirmation_controller_callback(conn, fn conn ->
      params   = Map.fetch!(conn.private, :pow_assent_callback_params)
      provider = Map.fetch!(conn.params, "provider")

      conn
      |> Plug.put_session(:callback_params, %{provider => params})
      |> Plug.put_session(:changeset, changeset)
      |> redirect(to: routes(conn).path_for(conn, RegistrationController, :add_user_id, [provider]))
    end)
  end
  def respond_callback({:error, conn}) do
    conn
    |> put_flash(:error, extension_messages(conn).could_not_sign_in(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

  defp trigger_registration_email_confirmation_controller_callback(conn, callback) do
    config        = PowPlug.fetch_config(conn)
    %{user: user} = conn.private[:pow_assent_callback_params]

    cond do
      email_verified?(user) ->
        callback.(conn)

      extension_enabled?(config, PowEmailConfirmation) ->
        Pow.Phoenix.RegistrationController
        |> EmailConfirmationCallbacks.before_respond(:create, to_email_confirmation_res(conn), config)
        |> case do
             {:ok, _user, conn}         -> callback.(conn)
             {:error, _changeset, conn} -> callback.(conn)
             {:halt, conn}              -> conn
           end

      true ->
        callback.(conn)
    end
  end

  defp to_email_confirmation_res(%{private: %{pow_assent_callback_state: {:error, _method}, pow_assent_callback_error: {_type, changeset}}} = conn) do
    {:error, changeset, conn}
  end
  defp to_email_confirmation_res(%{private: %{pow_assent_callback_state: {:ok, _method}}} = conn) do
    {:ok, PowPlug.current_user(conn), conn}
  end

  defp email_verified?(%{"email_verified" => true}), do: true
  defp email_verified?(%{email_verified: true}), do: true
  defp email_verified?(_params), do: false

  defp extension_enabled?(config, extension) do
    config
    |> ExtensionConfig.extensions()
    |> Enum.member?(extension)
  end

  defp trigger_session_email_confirmation_controller_callback(conn, callback) do
    config = PowPlug.fetch_config(conn)

    Pow.Phoenix.SessionController
    |> EmailConfirmationCallbacks.before_respond(:create, {:ok, conn}, config)
    |> case do
         {:ok, conn}   -> callback.(conn)
         {:halt, conn} -> conn
       end
  end

  defp assign_callback_url(conn, _opts) do
    url = routes(conn).url_for(conn, __MODULE__, :callback, [conn.params["provider"]])

    assign(conn, :callback_url, url)
  end

  defp init_session(conn, _opts), do: Plug.init_session(conn)

  defp assign_request_path(%{private: %{pow_assent_session: %{request_path: request_path}}} = conn, _opts) do
    conn
    |> Plug.delete_session(:request_path)
    |> Conn.assign(:request_path, request_path)
  end
  defp assign_request_path(conn, _opts), do: conn

  defp load_session_params(%{private: %{pow_assent_session: %{session_params: params}}} = conn, _opts) do
    conn
    |> Conn.put_private(:pow_assent_session_params, params)
    |> Plug.delete_session(:session_params)
  end
  defp load_session_params(conn, _opts), do: conn

  defp set_registration_option(%{private: %{pow_assent_registration: _any}} = conn, _opts), do: conn
  defp set_registration_option(conn, _opts), do: Conn.put_private(conn, :pow_assent_registration, registration_path?(conn))

  defp registration_path?(conn) do
    [conn.private.phoenix_router, Helpers]
    |> Module.concat()
    |> function_exported?(:pow_assent_registration_path, 3)
  end

  defp load_user_by_invitation_token(%{private: %{pow_assent_session: %{invitation_token: token}}} = conn, _opts) do
    conn = Plug.delete_session(conn, :invitation_token)

    conn
    |> PowInvitation.Plug.load_invited_user_by_token(token)
    |> case do
         {:error, conn} ->
           conn

         {:ok, %{assigns: %{invited_user: user}} = conn} ->
           config = PowPlug.fetch_config(conn)

           PowPlug.assign_current_user(conn, user, config)
       end
  end
  defp load_user_by_invitation_token(conn, _opts), do: conn

  defp handle_strategy_error(conn, error) do
    Logger.error("Strategy failed with error: #{inspect error}")

    conn
    |> put_flash(:error, extension_messages(conn).could_not_sign_in(conn))
    |> redirect(to: routes(conn).session_path(conn, :new))
  end

end

defmodule ExHackers.EchoServer do
  @moduledoc """
    [Protohackers 0](https://protohackers.com/problem/0)

  Deep inside Initrode Global's enterprise management framework lies a
  component that writes data to a server and expects to read the same data
  back. (Think of it as a kind of distributed system delay-line memory). We
  need you to write the server to echo the data back.

  Accept TCP connections.

  Whenever you receive data from a client, send it back unmodified.

  Make sure you don't mangle binary data, and that you can handle at least 5
  simultaneous clients.

  Once the client has finished sending data to you it shuts down its sending side.
  Once you've reached end-of-file on your receiving side, and sent back all the
  data you've received, close the socket so that the client knows you've finished.
  (This point trips up a lot of proxy software, such as ngrok; if you're using a
  proxy and you can't work out why you're failing the check, try hosting your server
  in the cloud instead).

  Your program will implement the TCP Echo Service from [RFC 862](https://www.rfc-editor.org/rfc/rfc862.html).
  """
  use GenServer

  require Logger

  @buffer_limit _100k = 1024 * 100

  @type t :: %__MODULE__{
    listen_socket: :gen_tcp.socket(),
    supervisor: Supervisor.on_start()
  }

  defstruct ~w(listen_socket supervisor)a

  @spec start_link(Keyword.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # GenServer API

  @impl true
  def init(opts) when is_list(opts) do
    port = Keyword.get(opts, :port, 5001)

    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    listen_options = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(port, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("[EchoServer] Starting echo server on port 5001")

        state = %__MODULE__{
          listen_socket: listen_socket,
          supervisor: supervisor
        }

        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.warn("[EchoServer] Error initalizing :gen_tcp - #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn  -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        Logger.warn("[EchoServer] Stopping gen_tcp server - #{inspect(reason)}")
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case recv_until_closed(socket, _buffer = "", _buffered_size = 0) do
      {:ok, data} ->
        :gen_tcp.send(socket, data)

      {:error, reason} ->
        Logger.warn("[EchoServer] Error receving data - #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp recv_until_closed(socket, buffer, buffered_size) do
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, data} when buffered_size + byte_size(data) > @buffer_limit ->
        {:error, :buffer_overflow}

      {:ok, data} ->
        recv_until_closed(socket, [buffer, data], buffered_size + byte_size(data))

      {:error, :closed} ->
        {:ok, buffer}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

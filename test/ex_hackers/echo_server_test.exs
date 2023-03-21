defmodule ExHackers.EchoServerTest do
  use ExUnit.Case, async: false

  @tag :capture_log
  test "echos binary data back unchanged" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
    assert :ok == :gen_tcp.send(socket, "foo")
    assert :ok == :gen_tcp.send(socket, "bar")
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, 5_000) == {:ok, "foobar"}
  end

  @tag :capture_log
  test "handles at least 5 concurrent connections" do
    tasks =
      for id <- 1..5 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, mode: :binary, active: false)
          assert :ok == :gen_tcp.send(socket, "foo#{id}")
          assert :ok == :gen_tcp.send(socket, "bar")
          :gen_tcp.shutdown(socket, :write)
          assert :gen_tcp.recv(socket, 0, 5_000) == {:ok, "foo#{id}bar"}
        end)
      end

    Task.await_many(tasks)
  end
end

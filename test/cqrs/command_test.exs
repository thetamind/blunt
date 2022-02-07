defmodule Cqrs.CommandTest do
  use ExUnit.Case, async: true

  alias Cqrs.CommandTest.Protocol
  alias Cqrs.{Command, DispatchContext}
  alias Cqrs.DispatchStrategy.PipelineResolver

  test "command options" do
    alias Protocol.CommandOptions
    options = CommandOptions.__options__() |> Enum.into(%{})

    assert %{
             audit: [{:type, :boolean}, {:required, false}, {:default, true}],
             debug: [{:type, :boolean}, {:required, false}, {:default, false}],
             return: [type: :enum, values: [:context, :response], default: :response, required: true]
           } == options
  end

  test "dispatch with no pipeline" do
    alias Protocol.DispatchNoPipeline

    error = "No Cqrs.CommandPipeline found for query: Cqrs.CommandTest.Protocol.DispatchNoPipeline"

    assert_raise(PipelineResolver.Error, error, fn ->
      %{name: "chris"}
      |> DispatchNoPipeline.new()
      |> DispatchNoPipeline.dispatch()
    end)
  end

  describe "dispatch" do
    alias Protocol.DispatchWithPipeline

    test "options" do
      options = DispatchWithPipeline.__options__() |> Enum.into(%{})

      assert %{
               reply_to: [type: :pid, default: nil, required: true],
               return: [type: :enum, values: [:context, :response], default: :response, required: true],
               return_error: [type: :boolean, required: false, default: false]
             } = options
    end

    test "command requires reply_to option to be set" do
      assert {:error, context} =
               %{name: "chris"}
               |> DispatchWithPipeline.new()
               |> DispatchWithPipeline.dispatch()

      assert %{reply_to: ["can't be blank"]} = Command.errors(context)
    end

    test "command requires reply_to option to be set to a valid Pid" do
      assert {:error, context} =
               %{name: "chris"}
               |> DispatchWithPipeline.new()
               |> DispatchWithPipeline.dispatch(reply_to: "lkajsdf")

      assert %{reply_to: ["is not a valid Pid"]} = Command.errors(context)
    end

    test "returns handle_dispatch result by default" do
      assert {:ok, "YO-HOHO"} =
               %{name: "chris"}
               |> DispatchWithPipeline.new()
               |> DispatchWithPipeline.dispatch(reply_to: self())
    end

    test "returns context if selected in option" do
      assert {:ok, context} =
               %{name: "chris"}
               |> DispatchWithPipeline.new()
               |> DispatchWithPipeline.dispatch(return: :context, reply_to: self())

      assert %{} == Command.errors(context)
      assert "YO-HOHO" = Command.results(context)
    end
  end

  describe "async dispatch" do
    alias Protocol.DispatchWithPipeline

    test "is simple" do
      assert task =
               %{name: "chris"}
               |> DispatchWithPipeline.new()
               |> DispatchWithPipeline.dispatch_async(return: :context, reply_to: self())

      assert {:ok, context} = Task.await(task)

      assert "YO-HOHO" = Command.results(context)
    end
  end

  describe "dispatch error simulations" do
    alias Protocol.DispatchWithPipeline

    test "simulate error in handle_dispatch" do
      {:error, context} =
        %{name: "chris"}
        |> DispatchWithPipeline.new()
        |> DispatchWithPipeline.dispatch(return_error: true, return: :context, reply_to: self())

      assert %{
               errors: [:handle_dispatch_error],
               last_pipeline_step: :handle_dispatch
             } = context

      assert %{generic: [:handle_dispatch_error]} = Command.errors(context)
      assert {:error, :handle_dispatch_error} == DispatchContext.get_last_pipeline(context)
    end
  end

  describe "event derivation" do
    alias Cqrs.CommandTest.Events.NamespacedEventWithExtrasAndDrops
    alias Protocol.{CommandWithEventDerivations, DefaultEvent, EventWithExtras, EventWithDrops, EventWithExtrasAndDrops}

    test "event structs are created" do
      %{} = %DefaultEvent{}
      %{} = %EventWithExtras{}
      %{} = %EventWithExtrasAndDrops{}
      %{} = %NamespacedEventWithExtrasAndDrops{}
    end

    test "are created and returned from pipeline" do
      {:ok, events} =
        %{name: "chris"}
        |> CommandWithEventDerivations.new()
        |> CommandWithEventDerivations.dispatch()

      today = Date.utc_today()

      assert %{
               default_event: %DefaultEvent{dog: "maize", name: "chris"},
               event_with_drops: %EventWithDrops{name: "chris"},
               event_with_extras: %EventWithExtras{dog: "maize", name: "chris", date: ^today},
               event_with_extras_and_drops: %EventWithExtrasAndDrops{name: "chris", date: ^today},
               namespaced_event_with_extras_and_drops: %NamespacedEventWithExtrasAndDrops{name: "chris", date: ^today}
             } = events
    end
  end
end

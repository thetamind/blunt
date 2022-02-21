defmodule Cqrs.Message do
  require Logger

  alias Cqrs.Message.{
    Changeset,
    Constructor,
    Dispatch,
    Documentation,
    Metadata,
    PrimaryKey,
    Schema,
    Schema.Fields,
    Version
  }

  defmodule Error do
    defexception [:message]
  end

  @type changeset :: Ecto.Changeset.t()

  @callback handle_validate(changeset()) :: changeset()
  @callback after_validate(struct()) :: struct()

  @moduledoc """
  ## Options

  * message_type - required atom
  * create_jason_encoders? - default value: `true`
  * require_all_fields? - default value: `false`
  * versioned? - default value: `false`
  * dispatch? - default value: `false`
  * primary_key - default value: `false`
  * constructor - default value: `:new`
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      use Cqrs.Message.Compilation

      require Cqrs.Message.{
        Constructor,
        Changeset,
        Dispatch,
        Documentation,
        Schema,
        Schema.Fields,
        Metadata,
        PrimaryKey,
        Version
      }

      Metadata.register(opts)
      Schema.register(opts)
      Version.register(opts)
      Dispatch.register(opts)
      PrimaryKey.register(opts)
      Constructor.register(opts)

      import Cqrs.Message, only: :macros

      @behaviour Cqrs.Message
      @before_compile Cqrs.Message

      @impl true
      def handle_validate(changeset),
        do: changeset

      @impl true
      def after_validate(message),
        do: message

      defoverridable handle_validate: 1, after_validate: 1
    end
  end

  defmacro __before_compile__(env) do
    # TODO This style of codegen is *very* appealing. Do more.
    doc = Documentation.generate_module_doc(env)

    rest =
      quote location: :keep do
        Version.generate()
        PrimaryKey.generate()
        Constructor.generate()
        Schema.generate()
        Changeset.generate()
        Dispatch.generate()
        Metadata.generate()
      end

    [doc, rest]
  end

  @spec field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro field(name, type, opts \\ []),
    do: Fields.record(name, type, opts)

  @spec metadata(atom(), any()) :: any()
  defmacro metadata(name, value),
    do: Metadata.record(name, value)

  @spec internal_field(name :: atom(), type :: atom(), keyword()) :: any()
  defmacro internal_field(name, type, opts \\ []) do
    opts =
      opts
      |> Keyword.put(:internal, true)
      |> Keyword.put(:required, false)

    Fields.record(name, type, opts)
  end

  def dispatchable?(%{__struct__: module}),
    do: dispatchable?(module)

  def dispatchable?(module) do
    case Cqrs.Behaviour.validate(module, __MODULE__) do
      {:ok, module} -> Metadata.dispatchable?(module)
      _ -> false
    end
  end

  defdelegate compile_start(message_module), to: Cqrs.Message.Compilation
end

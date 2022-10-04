defmodule Blunt.Test.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :line1, :string
    field :line2, :string
  end

  @behaviour Blunt.Message

  @impl true
  def handle_validate(changeset, _opts), do: changeset

  @impl true
  def after_validate(message), do: message

  @impl true
  def before_validate(values), do: values

  def changeset(address, attrs \\ %{}) do
    address
    |> cast(attrs, [:line1, :line2])
    |> validate_required([:line1])
    |> validate_length(:line1, min: 3)
  end
end

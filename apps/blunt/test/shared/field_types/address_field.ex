defmodule Blunt.Test.FieldTypes.AddressField do
  use Blunt.Message.Schema.FieldDefinition

  @impl true
  def define(:address, opts) do
    {Blunt.Test.Address, opts}
  end

  @impl true
  def define(__MODULE__, opts) do
    {Blunt.Test.Address, opts}
  end
end

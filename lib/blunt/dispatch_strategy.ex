defmodule Blunt.DispatchStrategy do
  alias Blunt.{Config, DispatchContext}

  @type context :: DispatchContext.t()

  @callback dispatch(context()) :: {:ok, context() | any()} | {:error, context()}

  def dispatch(context) do
    Config.dispatch_strategy!().dispatch(context)
  end

  @spec return_last_pipeline(context()) :: {:ok, any}
  def return_last_pipeline(context) do
    context
    |> DispatchContext.get_last_pipeline()
    |> return_final(context)
  end

  @spec return_final(any, context()) :: {:ok, any}
  def return_final(value, context) do
    DispatchContext.Shipper.ship(context)

    case DispatchContext.get_return(context) do
      :context -> {:ok, context}
      _ -> {:ok, value}
    end
  end

  @spec execute({atom, atom, list}, context()) :: {:error, context()} | {:ok, context()}
  def execute({pipeline, callback, args}, context) do
    case apply(pipeline, callback, args) do
      {:error, error} ->
        {:error,
         context
         |> DispatchContext.put_error(error)
         |> DispatchContext.put_pipeline(callback, {:error, error})}

      :error ->
        {:error,
         context
         |> DispatchContext.put_error(:error)
         |> DispatchContext.put_pipeline(callback, :error)}

      {:ok, %DispatchContext{} = context} ->
        {:ok, DispatchContext.put_pipeline(context, callback, :ok)}

      {:ok, {:ok, response}} ->
        {:ok, DispatchContext.put_pipeline(context, callback, response)}

      {:ok, response} ->
        {:ok, DispatchContext.put_pipeline(context, callback, response)}

      %DispatchContext{} = context ->
        {:ok, context}

      response ->
        {:ok, DispatchContext.put_pipeline(context, callback, response)}
    end
  end
end
defmodule Solana.ComputeBudget do
  import Solana.Helpers

  alias Solana.Instruction

  @set_compute_unit_limit_schema [
    limit: [
      type: :pos_integer,
      required: true,
      doc: "Compute unit limit"
    ]
  ]

  @set_compute_unit_price_schema [
    price: [
      type: :pos_integer,
      required: true,
      doc: "Compute unit price in micro lamports"
    ]
  ]

  def id, do: Solana.pubkey!("ComputeBudget111111111111111111111111111111")

  def set_compute_unit_limit(opts) do
    case validate(opts, @set_compute_unit_limit_schema) do
      {:ok, params} ->
        %Instruction{
          program: id(),
          data: Instruction.encode_data([2, {params.limit, 32}])
        }

      error ->
        error
    end
  end

  def set_compute_unit_price(opts) do
    case validate(opts, @set_compute_unit_price_schema) do
      {:ok, params} ->
        %Instruction{
          program: id(),
          data: Instruction.encode_data([3, {params.price, 64}])
        }

      error ->
        error
    end
  end
end

defmodule Solana.SPL.AssociatedToken do
  @moduledoc """
  Functions for interacting with the [Associated Token Account
  Program](https://spl.solana.com/associated-token-account).

  An associated token account's address is derived from a user's main system
  account and the token mint, which means each user can only have one associated
  token account per token.
  """
  import Solana.Helpers

  alias Solana.Account
  alias Solana.Instruction
  alias Solana.Key
  alias Solana.SPL.Token
  alias Solana.SystemProgram

  @doc """
  The Associated Token Account's Program ID
  """
  def id, do: Solana.pubkey!("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")

  @doc """
  Finds the token account address associated with a given owner and mint.

  This address will be unique to the mint/owner combination.
  """
  @spec find_address(mint :: Solana.key(), owner :: Solana.key()) :: {:ok, Solana.key()} | :error
  def find_address(mint, owner) do
    with true <- Cafezinho.valid_point?(owner),
         {:ok, key, _} <- Key.find_address([owner, Token.id(), mint], id()) do
      {:ok, key}
    else
      _ -> :error
    end
  end

  @create_account_schema [
    payer: [
      type: {:custom, Key, :check, []},
      required: true,
      doc: "The account which will pay for the `new` account's creation"
    ],
    owner: [
      type: {:custom, Key, :check, []},
      required: true,
      doc: "The account which will own the `new` account"
    ],
    new: [
      type: {:custom, Key, :check, []},
      required: true,
      doc: "Public key of the associated token account to create"
    ],
    mint: [
      type: {:custom, Key, :check, []},
      required: true,
      doc: "The mint of the `new` account"
    ]
  ]

  @doc """
  Creates an associated token account.

  This will be owned by the `owner` regardless of who actually creates it.

  ## Options

  #{NimbleOptions.docs(@create_account_schema)}
  """
  def create_account(opts) do
    do_create_account(opts, 0)
  end

  @doc """
  Creates an associated token account idempotently, ie it doesn't do anything if account is
  already created.

  This will be owned by the `owner` regardless of who actually creates it.

  ## Options

  #{NimbleOptions.docs(@create_account_schema)}
  """
  def create_account_idempotent(opts) do
    do_create_account(opts, 1)
  end

  defp do_create_account(opts, mode) do
    case validate(opts, @create_account_schema) do
      {:ok, params} ->
        %Instruction{
          program: id(),
          accounts: [
            %Account{key: params.payer, writable?: true, signer?: true},
            %Account{key: params.new, writable?: true},
            %Account{key: params.owner},
            %Account{key: params.mint},
            %Account{key: SystemProgram.id()},
            %Account{key: Token.id()},
            %Account{key: Solana.rent()}
          ],
          data: Instruction.encode_data([mode])
        }

      error ->
        error
    end
  end
end

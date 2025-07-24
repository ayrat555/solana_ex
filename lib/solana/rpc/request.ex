defmodule Solana.RPC.Request do
  @moduledoc """
  Functions for creating Solana JSON-RPC API requests.

  This client only implements the most common methods (see the function
  documentation below). If you need a method that's on the [full
  list](https://docs.solana.com/developing/clients/jsonrpc-api#json-rpc-api-reference)
  but is not implemented here, please open an issue or contact the maintainers.
  """

  @typedoc "JSON-RPC API request (pre-encoding)"
  @type t :: {String.t(), [String.t() | map]}

  @typedoc "JSON-RPC API request (JSON encoding)"
  @type json :: %{
          jsonrpc: String.t(),
          id: term,
          method: String.t(),
          params: list
        }

  @doc """
  Encodes a `t:Solana.RPC.Request.t/0` (or a list of them) in the [required
  format](https://docs.solana.com/developing/clients/jsonrpc-api#request-formatting).
  """
  @spec encode(requests :: [t]) :: [json]
  def encode(requests) when is_list(requests) do
    requests
    |> Enum.with_index()
    |> Enum.map(&to_json_rpc/1)
  end

  @spec encode(request :: t) :: json
  def encode(request), do: to_json_rpc({request, 0})

  defp to_json_rpc({{method, []}, id}) do
    %{jsonrpc: "2.0", id: id, method: method}
  end

  defp to_json_rpc({{method, params}, id}) do
    %{jsonrpc: "2.0", id: id, method: method, params: check_params(params)}
  end

  defp check_params([]), do: []
  defp check_params([%{} = map | rest]) when map_size(map) == 0, do: check_params(rest)
  defp check_params([elem | rest]), do: [elem | check_params(rest)]

  @doc """
  Returns all information associated with the account of the provided Pubkey.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getaccountinfo).
  """
  @spec get_account_info(account :: Solana.key(), opts :: keyword) :: t
  def get_account_info(account, opts \\ []) do
    {"getAccountInfo", [ExBase58.encode!(account), encode_opts(opts, %{"encoding" => "base64"})]}
  end

  @doc """
  Returns the balance of the provided pubkey's account.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getbalance).
  """
  @spec get_balance(account :: Solana.key(), opts :: keyword) :: t
  def get_balance(account, opts \\ []) do
    {"getBalance", [ExBase58.encode!(account), encode_opts(opts)]}
  end

  @spec get_token_account_balance(account :: Solana.key(), opts :: keyword) :: t
  def get_token_account_balance(account, opts \\ []) do
    {"getTokenAccountBalance", [ExBase58.encode!(account), encode_opts(opts)]}
  end

  @doc """
  Returns identity and transaction information about a confirmed block in the
  ledger.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getblock).
  """
  @spec get_block(slot :: non_neg_integer, opts :: keyword) :: t
  def get_block(slot, opts \\ []) do
    {"getBlock", [slot, encode_opts(opts)]}
  end

  @doc """
  Returns the current block height of the node

  For more information, see [the Solana
  docs](https://solana.com/docs/rpc/http/getblockheight).
  """
  @spec get_block(slot :: non_neg_integer, opts :: keyword) :: t
  def get_block_height(opts \\ []) do
    {"getBlockHeight", [encode_opts(opts)]}
  end

  @spec get_slot() :: t()
  def get_slot(opts \\ []) do
    {"getSlot", [encode_opts(opts)]}
  end

  @doc """
  Returns a recent block hash from the ledger, and a fee schedule that can be
  used to compute the cost of submitting a transaction using it.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getrecentblockhash).
  """
  @spec get_latest_blockhash(opts :: keyword) :: t
  def get_latest_blockhash(opts \\ []) do
    {"getLatestBlockhash", [encode_opts(opts)]}
  end

  @doc """
  Get the fee the network will charge for a particular Message

  For more information, see [the Solana
  docs](https://solana.com/docs/rpc/http/getfeeformessage).
  """
  @spec get_fee_for_message(binary(), opts :: keyword()) :: t
  def get_fee_for_message(message, opts \\ []) do
    {"getFeeForMessage", [message, encode_opts(opts)]}
  end

  @doc """
  Returns minimum balance required to make an account rent exempt.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getminimumbalanceforrentexemption).
  """
  @spec get_minimum_balance_for_rent_exemption(length :: non_neg_integer, opts :: keyword) :: t
  def get_minimum_balance_for_rent_exemption(length, opts \\ []) do
    {"getMinimumBalanceForRentExemption", [length, encode_opts(opts)]}
  end

  @doc """
  Submits a signed transaction to the cluster for processing.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#sendtransaction).
  """
  @spec send_transaction(transaction :: Solana.Transaction.t(), opts :: keyword) :: t
  def send_transaction(%Solana.Transaction{} = tx, opts \\ []) do
    {:ok, tx_bin} = Solana.Transaction.to_binary(tx)
    opts = opts |> fix_tx_opts() |> encode_opts(%{"encoding" => "base64"})
    {"sendTransaction", [Base.encode64(tx_bin), opts]}
  end

  defp fix_tx_opts(opts) do
    Enum.map(opts, fn
      {:commitment, commitment} -> {:preflight_commitment, commitment}
      other -> other
    end)
  end

  @doc """
  Requests an airdrop of lamports to an account.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#requestairdrop).
  """
  @spec request_airdrop(account :: Solana.key(), sol :: pos_integer, opts :: keyword) :: t
  def request_airdrop(account, sol, opts \\ []) do
    {"requestAirdrop", [ExBase58.encode(account), sol * Solana.lamports_per_sol(), encode_opts(opts)]}
  end

  @doc """
  Returns confirmed signatures for transactions involving an address backwards
  in time from the provided signature or most recent confirmed block.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getsignaturesforaddress).
  """
  @spec get_signatures_for_address(account :: Solana.key(), opts :: keyword) :: t
  def get_signatures_for_address(account, opts \\ []) do
    {"getSignaturesForAddress", [ExBase58.encode(account), encode_opts(opts)]}
  end

  @doc """
  Returns the statuses of a list of signatures.

  Unless the `searchTransactionHistory` configuration parameter is included,
  this method only searches the recent status cache of signatures, which retains
  statuses for all active slots plus `MAX_RECENT_BLOCKHASHES` rooted slots.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getsignaturestatuses).
  """
  @spec get_signature_statuses(signatures :: [Solana.key()], opts :: keyword) :: t
  def get_signature_statuses(signatures, opts \\ []) when is_list(signatures) do
    {"getSignatureStatuses", [Enum.map(signatures, &ExBase58.encode/1), encode_opts(opts)]}
  end

  @doc """
  Returns transaction details for a confirmed transaction.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#gettransaction).
  """
  @spec get_transaction(signature :: Solana.key(), opts :: keyword) :: t
  def get_transaction(signature, opts \\ []) do
    {"getTransaction", [ExBase58.encode(signature), encode_opts(opts)]}
  end

  @doc """
  Returns the total supply of an SPL Token.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#gettokensupply).
  """
  @spec get_token_supply(mint :: Solana.key(), opts :: keyword) :: t
  def get_token_supply(mint, opts \\ []) do
    {"getTokenSupply", [ExBase58.encode(mint), encode_opts(opts)]}
  end

  @doc """
  Returns the slot of the lowest confirmed block that has not been purged from the ledger.

  For more information, see [the Solana
  docs](https://www.quicknode.com/docs/solana/getFirstAvailableBlock).
  """
  @spec get_first_available_block() :: t()
  def get_first_available_block do
    {"getFirstAvailableBlock", []}
  end

  @doc """
  Returns the 20 largest accounts of a particular SPL Token type.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#gettokenlargestaccounts).
  """
  @spec get_token_largest_accounts(mint :: Solana.key(), opts :: keyword) :: t
  def get_token_largest_accounts(mint, opts \\ []) do
    {"getTokenLargestAccounts", [ExBase58.encode(mint), encode_opts(opts)]}
  end

  @doc """
  Returns the account information for a list of pubkeys.

  For more information, see [the Solana
  docs](https://docs.solana.com/developing/clients/jsonrpc-api#getmultipleaccounts).
  """
  @spec get_multiple_accounts(accounts :: [Solana.key()], opts :: keyword) :: t
  def get_multiple_accounts(accounts, opts \\ []) when is_list(accounts) do
    {"getMultipleAccounts", [Enum.map(accounts, &ExBase58.encode/1), encode_opts(opts, %{"encoding" => "base64"})]}
  end

  defp encode_opts(opts, defaults \\ %{}) do
    Enum.into(opts, defaults, fn {k, v} -> {camelize(k), encode_value(v)} end)
  end

  defp camelize(word) do
    case Regex.split(~r/(?:^|[-_])|(?=[A-Z])/, to_string(word)) do
      words ->
        words
        |> Enum.filter(&(&1 != ""))
        |> camelize_list(:lower)
        |> Enum.join()
    end
  end

  defp camelize_list([], _), do: []

  defp camelize_list([h | tail], :lower) do
    [String.downcase(h)] ++ camelize_list(tail, :upper)
  end

  defp camelize_list([h | tail], :upper) do
    [String.capitalize(h)] ++ camelize_list(tail, :upper)
  end

  defp encode_value(v) do
    cond do
      :ok == elem(Solana.Key.check(v), 0) -> ExBase58.encode(v)
      :ok == elem(Solana.Transaction.check(v), 0) -> ExBase58.encode(v)
      true -> v
    end
  end
end

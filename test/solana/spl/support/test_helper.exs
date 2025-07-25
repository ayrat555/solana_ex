alias Solana.TestValidator

extra_programs = [
  {Solana.SPL.TokenSwap, ["solana-program-library", "target", "deploy", "spl_token_swap.so"]},
  ["solana-program-library", "target", "deploy", "spl_governance"]
]

opts = [
  ledger: "/tmp/test-ledger",
  bpf_program:
    Enum.map(extra_programs, fn
      {mod, path} ->
        Enum.join([ExBase58.encode58(mod.id()), Path.expand(Path.join(["deps" | path]))], " ")

      path ->
        [name | rest] = Enum.reverse(path)
        keypair_file_path = Enum.reverse([name <> "-keypair.json" | rest])

        id =
          ["deps" | keypair_file_path]
          |> Path.join()
          |> Path.expand()
          |> Solana.Key.pair_from_file()
          |> elem(1)
          |> Solana.pubkey!()

        path = Enum.reverse([name <> ".so" | rest])

        Enum.join([ExBase58.encode(id), Path.expand(Path.join(["deps" | path]))], " ")
    end)
]

# {:ok, validator} = TestValidator.start_link(opts)
# ExUnit.after_suite(fn _ -> TestValidator.stop(validator) end)
ExUnit.start()

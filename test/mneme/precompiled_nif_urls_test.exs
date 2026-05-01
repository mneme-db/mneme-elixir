defmodule Mneme.PrecompiledNifUrlsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # Must match `lib/mneme/native.ex` `nif_targets` and `.github/workflows/precompiled-nifs.yml` matrix.
  @triples ~w(
    aarch64-linux-gnu
    x86_64-linux-gnu
    aarch64-macos-none
    x86_64-macos-none
  )

  test "release path and filenames match ZiglerPrecompiled (v in URL path and in each asset name)" do
    version = Mix.Project.config()[:version]
    basename = "Elixir.Mneme.Native"
    tag = "v#{version}"

    for triple <- @triples do
      lib = ZiglerPrecompiled.lib_name(basename, version, triple)
      filename = ZiglerPrecompiled.lib_name_with_ext(triple, lib)

      assert filename == "#{basename}-v#{version}-#{triple}.so.tar.gz"

      base = "https://github.com/mneme-db/mneme-elixir/releases/download/#{tag}"
      {url, _headers} = ZiglerPrecompiled.tar_gz_file_url(base, filename)
      assert url == "#{base}/#{filename}"
    end
  end
end

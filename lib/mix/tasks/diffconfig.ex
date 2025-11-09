defmodule Mix.Tasks.Diffconfig do
  use Mix.Task

  @shortdoc "Diff two configuration dumps and show the differences"

  @moduledoc """
  Diff two configuration dumps and show the differences.

  ## Usage

      mix diffconfig [OPTIONS] CONFIG_DUMP_FILE_1 CONFIG_DUMP_FILE_2

  ## Options

  - `--color` - Enable syntax highlighting in the output (default: `true`)
  - `--no-color` - Don't use colors in the output

  ## See Also

  - `mix diffconfig.dump` - Dump the current configuration to a file
  - `mix diffconfig.read` - Read the contents of a diffconfig dump file

  """

  @default_opts [
    color: true
  ]

  def run(args) do
    {opts, remaining_args, _} =
      OptionParser.parse(args,
        strict: [color: :boolean]
      )

    opts = Keyword.merge(@default_opts, opts)

    if length(remaining_args) != 2 do
      Mix.raise("Please provide exactly two configuration dump files to compare")
    end

    [file1, file2] = remaining_args

    {:ok, [config1]} = :file.consult(file1)
    {:ok, [config2]} = :file.consult(file2)

    Diffident.explain(config1, config2)
    |> inspect(
      pretty: true,
      limit: :infinity,
      syntax_colors:
        if(opts[:color],
          do: [
            atom: :blue,
            string: :green,
            number: :red
          ],
          else: []
        )
    )
    |> Mix.shell().info()
  end
end

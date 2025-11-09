defmodule Mix.Tasks.Diffconfig.Read do
  use Mix.Task

  @shortdoc "Read the contents of a diffconfig dump file"

  @moduledoc """
  Read the contents of a diffconfig dump file.

  ## Usage

      mix diffconfig.read [OPTIONS} DUMP_FILE_PATH

  ### Options

  - `--color` - Enable syntax highlighting in the output (default: `true)
  - `--no-color` - Disable syntax highlighting in the output

  ## See Also

  - `mix diffconfig` - Diff two configuration dumps and show the differences
  - `mix diffconfig.dump` - Dump the current configuration to a file

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

    path = List.first(remaining_args) || raise "Please provide a path to the dump file"

    {:ok, [envs]} = :file.consult(path)
    # Add :color strict switch
    inspect(
      envs,
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

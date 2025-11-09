defmodule Mix.Tasks.Diffconfig.Dump do
  use Mix.Task

  @shortdoc "Dumps the current configuration to a file"

  @default_output_path_template "diffconfig.dump.~s.~s.term"

  @moduledoc """
  Dumps the current configuration to a file.

  ## Usage

      mix diffconfig.dump [OPTIONS] [OUTPUT_PATH]

  If `OUTPUT_PATH` is not provided, it defaults to:

      diffconfig.dump.{env}.{timestamp}.term

  Where:
  - `env` is the current Mix environment (e.g., `dev`, `prod`, `test`)
  - `timestamp` is the current UTC timestamp in condensed ISO8601 format.

  ## Options

  - `--config` - Specify the path to the configuration files (default: "config")
  - `--show-env` - If set, output the environment variables detected in the configuration files and their current values
  - `--static` - If set, the task will all set all environment variables detected in the configuration files to static values (default: false)
    - Most values will be set to "LOREMIPSUM"
    - To satisfy common validations:
      - Variables ending in _PORT are set to "1234"
      - Variables ending in _POOL_SIZE are set to "3"
      - Variables ending in _ID or set to "123"
      - Variables ending in _IDS are set to "321,123"
    - To set specific environment variables, use the `--dotenv` option. Those values will override.
    - To see the environment variables that will be set, use the `--env-vars` option in conjunction.
  - `--dotenv` - If set, the task will load environment variables.
    - Use this in conjunction with `--static` to override the static values with custom values.
    - Use this in conjunction with `--show-env` to show the environment variables that will be set.

  ## See Also

  - `mix diffconfig` - Diff two configuration dumps and show the differences
  - `mix diffconfig.read` - Read the contents of a diffconfig dump file

  """

  @default_opts [
    static: false,
    verbose: false,
    dotenv: nil,
    show_env: false,
    config: "config"
  ]

  def run(args) do
    {opts, remaining_args, _} =
      OptionParser.parse(args,
        strict: [
          show_env: :boolean,
          static: :boolean,
          config: :string,
          dotenv: :string,
          verbose: :boolean
        ],
        aliases: [v: :verbose]
      )

    @default_opts
    |> Keyword.merge(opts)
    |> Map.new()
    |> do_run(remaining_args)
  end

  def do_run(%{show_env: true} = opts, _remaining_args) do
    build_env(opts)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.each(&IO.puts/1)
  end

  def do_run(opts, remaining_args) do
    output_path = List.first(remaining_args)

    output_path =
      if output_path do
        output_path
      else
        timestamp =
          DateTime.utc_now()
          |> DateTime.truncate(:second)
          |> DateTime.to_iso8601(:basic)

        :io_lib.format(
          @default_output_path_template,
          [Mix.env(), timestamp]
        )
        |> List.to_string()
      end

    build_env(opts)
    |> Enum.each(fn
      {_k, nil} ->
        :skip

      {k, v} ->
        System.put_env(k, v)
    end)

    config =
      get_config()

    File.write!(output_path, :io_lib.format(~c"~p.\n", [config]))

    Mix.shell().info(output_path)
  end

  defp build_env(opts) do
    vars =
      scan_env_vars(opts[:config])

    data =
      if opts[:static] do
        Enum.reduce(vars, %{}, fn var, acc ->
          Map.put(acc, var, static_value(var))
        end)
      else
        Enum.reduce(vars, %{}, fn var, acc ->
          Map.put(acc, var, System.get_env(var))
        end)
      end

    read_dotenv(opts[:dotenv])
    |> Enum.reduce(data, fn {k, v}, acc ->
      Map.put(acc, k, v)
    end)
  end

  defp static_value(var) do
    cond do
      String.ends_with?(var, "_PORT") -> "1234"
      String.ends_with?(var, "_POOL_SIZE") -> "3"
      String.ends_with?(var, "_ID") -> "123"
      String.ends_with?(var, "_IDS") -> "321,123"
      String.contains?(var, "ENABLE") -> "true"
      true -> "LOREMIPSUM"
    end
  end

  defp scan_env_vars(path) do
    for file <- Path.wildcard(Path.join(path, "/**/*.exs")) do
      contents = File.read!(file)
      Regex.scan(~r/"([A-Z][A-Z0-9_]+)"/, contents, capture: :all_but_first)
    end
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp read_dotenv(nil), do: %{}

  defp read_dotenv(path) do
    if File.exists?(path) do
      File.read!(path)
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, value] -> {key, value}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Map.new()
    else
      %{}
    end
  end

  defp get_config() do
    Mix.Task.run("app.config")

    apps =
      :application.loaded_applications()
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    for app <- apps do
      {app, Application.get_all_env(app)}
    end
  end
end

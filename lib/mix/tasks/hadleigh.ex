defmodule Mix.Tasks.Hadleigh do
  @shortdoc "Export entry list from supplied URL to CSV"
  @moduledoc false
  use Mix.Task

  def run([url]) do
    Application.ensure_all_started(:req)
    req = [http_errors: :raise] |> Req.new() |> ReqEasyHTML.attach()
    file = File.open!("hadleigh.csv", [:write, :utf8])
    req |> get_entrants(url) |> CSV.encode() |> Enum.each(&IO.write(file, &1))
  end

  defp get_entrants(req, url) do
    IO.puts(:stderr, url)
    body = Req.get!(req, url: url).body
    entrants = Enum.map(body["tbody tr"], &extract_fields/1)

    case Enum.find(body["li.page-item:not(.disabled) a.page-link"], &(to_string(&1) =~ "next")) do
      nil ->
        entrants

      next_link ->
        path = to_string(Floki.attribute(next_link.nodes, "href"))
        next_url = url |> URI.parse() |> URI.merge(path)
        entrants ++ get_entrants(req, next_url)
    end
  end

  defp extract_fields(tr) do
    Enum.map(tr["td"], &to_string/1)
  end
end

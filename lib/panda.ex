defmodule Panda do
  @moduledoc """
  Documentation for Panda.
  """

  @doc """
  Upcoming matches
  Retrieve the 5 next upcoming matches from the Pandascore API

  ## Examples

      iex> Panda.upcoming_matches
      [
        %{"begin_at" => "2018-08-01T08:00:00Z", "id" => 49634, "name" => "BBQ-vs-GEN"},
        %{"begin_at" => "2018-08-01T09:00:00Z", "id" => 50149, "name" => "CR vs VG"},
        %{"begin_at" => "2018-08-01T09:00:00Z", "id" => 49780, "name" => "VG-vs-TOP"},
        %{"begin_at" => "2018-08-01T11:00:00Z", "id" => 49705, "name" => "JDG-vs-EDG"},
        %{"begin_at" => "2018-08-01T11:00:00Z", "id" => 49659, "name" => "SKT-vs-AFS"}
      ]

  """
  def upcoming_matches do
    response = HTTPotion.get "https://api.pandascore.co/matches/upcoming.json?token=#{Application.fetch_env!(:panda, :api_key)}"
    {:ok, all_matches} = Poison.decode(response.body)
    full_matches = Enum.take(all_matches, 5)
    for match <- full_matches do
      %{"begin_at" => match["begin_at"], "id" => match["id"], "name" => match["name"]}
    end
  end

  @doc """
  Odds for match
  Computes each opponent's chances of victory in an upcoming match based on previous tournaments results

  Reasoning used is coming from this article : https://sabr.org/research/probabilities-victory-head-head-team-matchups

  ## Examples

      iex> Panda.odds_for_match(49634)
      %{"Gen.G" => 80.0, "bbq OLIVERS" => 20.0}
  """
  def odds_for_match(match_id) do
    response = HTTPotion.get "https://api.pandascore.co/matches/upcoming.json?token=#{Application.fetch_env!(:panda, :api_key)}"
    {:ok, all_matches} = Poison.decode(response.body)

    filter =  Enum.filter(all_matches, fn x -> x["id"] == match_id end)
    if filter != [] do
      [match] = filter

      videogame = get_match_videogame(match)

      previous_matches = get_previous_matches(match["tournament_id"], videogame)

      teams =
        match["opponents"]
        |> Enum.map(&async_get_team_winrate(&1["opponent"], previous_matches))
        |> Enum.map(fn(_) -> get_result() end)

      w1 = Enum.fetch!(teams,0).winrate*(1-Enum.fetch!(teams,1).winrate)
      w2 = Enum.fetch!(teams,1).winrate*(1-Enum.fetch!(teams,0).winrate)
      p1 = w1 * 100 / (w1 + w2)
      p2 = w2  * 100/ (w2 + w1)

      %{Enum.fetch!(teams,0).team_name => p1, Enum.fetch!(teams,1).team_name => p2}
    else
      "No data for this match"
    end
  end

  def get_match_videogame(match) do
    case match["videogame"]["id"] do
      1 ->
        "lol"
      4 ->
        "dota2"
      14 ->
        "ow"
    end
  end

  def get_previous_matches(tournament_id, videogame) do
    response = HTTPotion.get "https://api.pandascore.co/#{videogame}/matches.json?token=#{Application.fetch_env!(:panda, :api_key)}&filter[tournament_id]=#{tournament_id}"
    {:ok, all_matches} = Poison.decode(response.body)
    all_matches
  end

  def get_team_winrate(team, all_matches) do
    team_matches = Enum.filter(all_matches, fn x -> is_team_in_match(team["id"], x) end)
    total = Enum.reduce(team_matches, 0, fn x, acc -> acc + Enum.count(x["games"]) end)
    wins = Enum.reduce(team_matches, 0, fn x, acc -> acc + Enum.count(x["games"], fn y -> y["winner"]["id"] == team["id"] end) end)
    %{:team_name => team["name"], :team_id => team["id"], :winrate =>  wins/total}
  end

  def async_get_team_winrate(team, previous_matches) do
    caller = self()
    spawn(fn ->
      send(caller, {:result, get_team_winrate(team, previous_matches)})
    end)
  end

  def get_result do
    receive do
      {:result, result} -> result
    end
  end

  def is_team_in_match(team_id, match) do
    Enum.any?(match["opponents"], fn x -> x["opponent"]["id"] == team_id end)
  end

end

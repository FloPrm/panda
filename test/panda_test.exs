defmodule PandaTest do
  use ExUnit.Case
  doctest Panda

  test "Upcoming matches" do
    assert length(Panda.upcoming_matches()) == 5
  end

  test "Basic Odds" do
    match_id = Enum.random(Panda.upcoming_matches)["id"]
    assert Map.values(Panda.odds_for_match(match_id))
      |> Enum.reduce(0, fn x, acc -> acc + x end) == 100
  end
end

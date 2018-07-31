defmodule Panda do
  @moduledoc """
  Documentation for Panda.
  """

  @doc """
  Upcoming matches
  Retrieve the 5 next upcoming matches from the Pandascore API

  ## Examples

      iex> PandascoreTechTest.upcoming_matches
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

end

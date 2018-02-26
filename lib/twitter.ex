defmodule Twitter do
  def start(hashtags) when is_list(hashtags) do
    hashtags
    |> Enum.map(fn(hashtag) ->
        Task.async(fn -> subscribe(hashtag) end)
      end)
    |> fetch
  end

  def start(hashtag) do
    stream = ExTwitter.stream_filter(track: hashtag)
    |> Stream.map(fn(tweet) -> %{"text" => tweet.text, "author" => tweet.user.screen_name} end)
    |> Stream.map(fn(tweet) -> save(tweet, hashtag) end)
    stream |> Enum.to_list |> IO.inspect
  end

  defp fetch(tasks) do
    Enum.each(tasks, fn(task) ->
      task |> Task.await(100000)
    end)
  end

  defp subscribe(hashtag) do
    stream = ExTwitter.stream_filter(track: hashtag)
    |> Stream.map(fn(tweet) -> %{"text" => tweet.text, "author" => tweet.user.screen_name} end)
    |> Stream.map(fn(tweet) -> save(tweet, hashtag) end)
    Enum.to_list(stream)
  end

  defp save(%{"author" => author, "text" => text}, hashtag) do
    Sqlitex.with_db('db.sqlite3', fn(db) ->
      Sqlitex.query(
        db,
        "INSERT INTO tweets (text, author, hashtag) VALUES ($1, $2, $3)",
        bind: [text, author, hashtag])
    end)
  end
end

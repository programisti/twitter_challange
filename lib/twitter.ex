defmodule Twitter do
  def subscribe(hashtags) when is_list(hashtags) do
    hashtags
    |> Enum.map(fn(hashtag) ->
      Task.async(fn -> search(hashtag) end)
      end)
    |> fetch
  end

  def subscribe(hashtag) when is_binary(hashtag) do
    Task.async(fn -> search(hashtag) end)
    |> fetch
  end

  defp fetch(tasks) do
    Enum.each(tasks, fn(task) ->
      task |> Task.await |> save
    end)
  end

  defp search(hashtag) do
    ExTwitter.search(hashtag, [count: 5])
    |> Enum.map(fn(tweet) -> %{"text" => tweet.text, "author" => tweet.user.screen_name} end)
  end

  defp save(tweets) do
    tweets
    |> Enum.map(fn(%{"author" => author, "text" => text}) ->
      Sqlitex.with_db('db.sqlite3', fn(db) ->
        Sqlitex.query(
          db,
          "INSERT INTO tweets (text, author) VALUES ($1, $2)",
          bind: [text, author])
      end)
    end)

  end
end

defmodule Twitter do
  def subscribe(hashtags) when is_list(hashtags) do
    hashtags
    |> Enum.map(fn(hashtag) ->
      Task.async(fn -> search(hashtag) end)
      end)
    |> fetch
  end

  def subscribe(hashtag) when is_binary(hashtag) do
    IO.inspect "------- STARTED for #{hashtag} ---------"
    Task.async(fn -> search(hashtag) end)
    |> fetch
  end

  defp fetch(tasks) do
    Enum.each(tasks, fn(task) ->
      task |> Task.await
    end)
  end

  defp search(hashtag) do
    IO.inspect "-------- subscribing to #{hashtag} ------------"
    ExTwitter.search(hashtag, [count: 5])
    |> Enum.map(fn(tweet) -> %{"text" => tweet.text, "author" => tweet.user.screen_name} end)
    |> save(hashtag)
  end

  defp save(tweets, hashtag) do
    tweets
    |> Enum.map(fn(%{"author" => author, "text" => text}) ->
      IO.inspect "-------- Saving to DB hashTag: #{hashtag} text: #{String.slice(text, 0..25)}"
      Sqlitex.with_db('db.sqlite3', fn(db) ->
        Sqlitex.query(
          db,
          "INSERT INTO tweets (text, author, hashtag) VALUES ($1, $2, $3)",
          bind: [text, author, hashtag])
      end)
    end)
    IO.inspect "-------- SAVING TO DB DONE for hashtag: #{hashtag}------------"

  end
end

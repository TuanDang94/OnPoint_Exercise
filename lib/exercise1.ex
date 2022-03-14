defmodule Exercise1 do
  #
  @derive [Poison.Encoder]
  import Kernel, except: [inspect: 1]
  import IO

  @doc """
  Struct Movie: collect info movie's
  """
  defmodule Movie do
    defstruct title: nil,
              link: nil,
              full_series: nil,
              number_of_episode: nil,
              thumnail: nil,
              year: nil
  end

  @doc """
  Struct MovieCartoonCollection: collection cartoon movie
  """
  defmodule MovieCartoonCollection do
    defstruct crawled_at: nil, total: nil, items: [%Movie{}]
  end

  @doc """
  Function HTTP Client get data from web by URL
  Parameter "pagenumber": Page number need to get data movie
  """
  def httpoisonResponse(pagenumber) do
    # Load page 1, we use url --> "https://ezphimmoi.net/category/hoat-hinh/". If load page 2 to N, we use url --> #"https://ezphimmoi.net/category/hoat-hinh/page/1/"
    url = "https://ezphimmoi.net/category/hoat-hinh/"

    url =
      if pagenumber > 1 do
        url =
          "https://ezphimmoi.net/category/hoat-hinh/page/" <> Integer.to_string(pagenumber) <> "/"
      else
        url = "https://ezphimmoi.net/category/hoat-hinh/"
      end

    """
    HTTPoison is used to get crawl data from web
    """

    """
    Floki is used to parse data HTML
    """
    {:ok, document} =
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          {:ok, document} = Floki.parse_document(body)

        _ ->
          {:ok, nil}
      end

    if is_nil(document) do
      inspect("Page not found")
    else
      """
      Get list film name
      """

      filmName =
        document
        |> Floki.find("a.movie-item")
        |> Floki.attribute("title")
        |> Enum.map(&Floki.text/1)
        # |> Enum.map(fn title -> %{title: title} end)
        |> Enum.map(&String.replace(&1, ["\n", "\t"], ""))

      """
      Get list film link
      """

      filmURL =
        document
        |> Floki.find("a.movie-item")
        |> Floki.attribute("href")
        |> Enum.map(&Floki.text/1)

      """
      Get list film episode
      """

      filmEpisode =
        document
        |> Floki.find("span.ribbon")
        |> Enum.map(&Floki.text/1)

      """
      Get list info series is Full or not?
      """

      filmIsFullSeries =
        document
        |> Floki.find("span.ribbon")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(fn title ->
          if String.contains?(title, ["FULL", "Full"]) do
            true
          else
            false
          end
        end)

      """
      Get list info year of film
      """

      filmYear =
        document
        |> Floki.find("span.movie-title-2")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(fn title ->
          if String.contains?(title, ["(", ")"]) do
            String.slice(title, -5, 4)
          else
            {:error, "No year"}
          end
        end)

      """
      Get list image of film
      """

      filmImage =
        document
        |> Floki.find("div.public-film-item-thumb")
        |> Floki.attribute("style")
        # |> Enum.map(&Floki.text/1)
        |> Enum.map(fn title -> elem(Enum.fetch(String.split(title, "'"), 1), 1) end)
        # |> Enum.map(&(Enum.fetch(&1,1)))     #|> Enum.map(fn title -> Enum.fetch(title,1) end)

      """
      Collect film to list movies
      """

      movieCollection = [%Movie{}]

      movieCollection =
        Enum.map(
          0..(Enum.count(filmName) - 1),
          fn x ->
            item = %Movie{}
            item = %{item | title: elem(Enum.fetch(filmName, x), 1)}
            item = %{item | thumnail: elem(Enum.fetch(filmImage, x), 1)}
            item = %{item | link: elem(Enum.fetch(filmURL, x), 1)}
            item = %{item | number_of_episode: elem(Enum.fetch(filmEpisode, x), 1)}
            item = %{item | year: elem(Enum.fetch(filmYear, x), 1)}
            item = %{item | full_series: elem(Enum.fetch(filmIsFullSeries, x), 1)}
          end
        )
    end
  end

  @doc """
  Function get max page, need to loop For to get data movie page by page
  """
  def getMaxPage do
    url = "https://ezphimmoi.net/category/hoat-hinh/"

    """
    HTTPoison is used to get crawl data from web
    """

    {:ok, document} =
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
          {:ok, document} = Floki.parse_document(body)

        _ ->
          {:ok, nil}
      end

    maxpage = if is_nil(document) do
        inspect("Page not found")
        maxpage = 0
    else
      """
      Get list pagination
      """
      """
      Floki is used to parse data HTML
      """
      pagination =
        document
        |> Floki.find("ul.pagination>li")
        |> Enum.map(&Floki.text/1)

      numberpage = elem(Enum.fetch(pagination, Enum.count(pagination) - 2), 1)
      maxpage = String.to_integer(numberpage)
    end

  end

  @doc """
  Main function: crawl data, format data and write data to file by format JSon
  """
  def crawlyMovie do
    maxpage = getMaxPage
    inspect maxpage
    if maxpage == 0 do
      inspect("Page not found")
    else
      movieCollections = [%Movie{}]

      movieCollections =
        for x <- 1..maxpage do
          dataRespone = httpoisonResponse(x)
        end

      movieCollections = List.flatten(movieCollections)

      cartoonCollection = %MovieCartoonCollection{}

      cartoonCollection = %{
        cartoonCollection
        | crawled_at: DateTime.to_iso8601(DateTime.utc_now() |> DateTime.add(7 * 3600, :second))
      }

      cartoonCollection = %{cartoonCollection | total: Enum.count(movieCollections)}
      cartoonCollection = %{cartoonCollection | items: movieCollections}

      # Code convert data to JSon string
      listdata = convertStruct2List(cartoonCollection)
      inspect(listdata)

      {status, result} = JSON.encode(listdata)

      writeData2File(result)

    end
  end

  @doc """
  Function write data to file
  Parameter "content": Content need to write to file.Json
  """
  def writeData2File(content) do
    # Code write data to file
    File.write!("priv/output/moviedata.json", content)
  end

  @doc """
  Function convert Struct object to List object
  paramter "structer": Struct object need to convert to list object
  """
  def convertStruct2List(structer) do
    listMovie = [
      crawled_at: structer.crawled_at,
      total: structer.total,
      items:
        structer.items
        |> Enum.map(fn item ->
          %{
            title: item.title,
            link: item.link,
            full_series: item.full_series,
            number_of_episode: item.number_of_episode,
            thumnail: item.thumnail,
            year: item.year
          }
        end)
    ]
  end
end

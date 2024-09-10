defmodule OpenaiEx.Http do
  @moduledoc false
  alias OpenaiEx.Http.Finch, as: Client

  def post(openai = %OpenaiEx{}, url) do
    post(openai, url, json: %{})
  end

  def post(openai = %OpenaiEx{}, url, multipart: multipart) do
    Client.post(openai, url, multipart: multipart) |> handle_response()
  end

  def post(openai = %OpenaiEx{}, url, json: json) do
    Client.post(openai, url, json: json) |> handle_response()
  end

  def post_no_decode(openai = %OpenaiEx{}, url, json: json) do
    Client.post(openai, url, json: json) |> extract_body()
  end

  def get(openai = %OpenaiEx{}, base_url, params) do
    query =
      base_url
      |> URI.new!()
      |> URI.append_query(params |> URI.encode_query())
      |> URI.to_string()

    openai |> get(query)
  end

  def get(openai = %OpenaiEx{}, url) do
    Client.get(openai, url) |> handle_response()
  end

  def get_no_decode(openai = %OpenaiEx{}, url) do
    Client.get(openai, url) |> extract_body()
  end

  def delete(openai = %OpenaiEx{}, url) do
    Client.delete(openai, url) |> handle_response()
  end

  def to_multi_part_form_data(req, file_fields) do
    mp =
      req
      |> Map.drop(file_fields)
      |> Enum.reduce(Multipart.new(), fn {k, v}, acc ->
        acc |> Multipart.add_part(Multipart.Part.text_field(v, k))
      end)

    req
    |> Map.take(file_fields)
    |> Enum.reduce(mp, fn {k, v}, acc ->
      acc |> Multipart.add_part(to_file_field_part(k, v))
    end)
  end

  defp to_file_field_part(k, v) do
    case v do
      {path} ->
        Multipart.Part.file_field(path, k)

      {filename, content} ->
        Multipart.Part.file_content_field(filename, content, k, filename: filename)

      content ->
        Multipart.Part.file_content_field("", content, k, filename: "")
    end
  end

  defp handle_response(response) do
    response |> extract_body() |> jsonify()
  end

  defp extract_body(response) do
    case response do
      {:ok, response} -> {:ok, response.body}
      _ -> response
    end
  end

  defp jsonify(response) do
    case response do
      {:ok, response} -> {:ok, Jason.decode!(response)}
      _ -> response
    end
  end

  def bang_it!(response) do
    case response do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end
end

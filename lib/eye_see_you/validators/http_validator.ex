defmodule EyeSeeYou.Validators.HttpValidator do
  @moduledoc """
  Utilities for validating HTTP-related data.
  """

  @http_methods ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"]

  @doc """
  Returns a list of valid HTTP methods.
  """
  @spec http_methods() :: list(String.t())
  def http_methods, do: @http_methods

  @doc """
  Checks if the provided value is a valid HTTP method.
  """
  @spec valid_http_method?(String.t()) :: boolean()
  def valid_http_method?(method) when is_binary(method), do: method in @http_methods

  def valid_http_method?(_), do: false

  @doc """
  Validates that the headers list contains properly formatted entries.
  Each header should be a map with "name" and "value" keys.
  """
  @spec valid_headers?(list()) :: boolean()
  def valid_headers?(headers) when is_list(headers) do
    Enum.all?(headers, fn header ->
      is_map(header) and Map.has_key?(header, "name") and Map.has_key?(header, "value")
    end)
  end

  def valid_headers?(_), do: false

  @doc """
  Validates headers in an Ecto changeset field.
  """
  @spec validate_headers(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_headers(changeset, field) do
    import Ecto.Changeset, only: [get_change: 2, validate_change: 3]

    headers = get_change(changeset, field)

    if is_nil(headers) do
      changeset
    else
      validate_change(changeset, field, fn _, headers ->
        cond do
          not is_list(headers) ->
            [{field, "must be a list of headers"}]

          not valid_headers?(headers) ->
            [
              {field,
               "contains invalid headers - each header must have 'name' and 'value' fields"}
            ]

          true ->
            []
        end
      end)
    end
  end
end

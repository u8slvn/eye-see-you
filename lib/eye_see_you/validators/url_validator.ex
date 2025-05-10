defmodule EyeSeeYou.Validators.UrlValidator do
  @moduledoc """
  Utilities for validating URLs.
  """

  @doc """
  Validates that a URL is a properly formatted HTTP or HTTPS URL.
  Returns an empty list if valid, or a list with an error tuple if invalid.
  """
  @spec valid_http_url?(String.t()) :: boolean()
  def valid_http_url?(url) when is_binary(url) do
    uri = URI.parse(url)

    not is_nil(uri.scheme) and uri.scheme in ["http", "https"] and not is_nil(uri.host) and
      uri.host != ""
  end

  def valid_http_url?(_), do: false

  @doc """
  Validates a URL in an Ecto changeset field.
  """
  @spec validate_http_url(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_http_url(changeset, field) do
    import Ecto.Changeset, only: [validate_change: 3]

    validate_change(changeset, field, fn _, url ->
      if valid_http_url?(url) do
        []
      else
        [{field, "is not a valid HTTP URL"}]
      end
    end)
  end
end

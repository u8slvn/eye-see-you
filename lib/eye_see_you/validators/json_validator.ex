defmodule EyeSeeYou.Validators.JsonValidator do
  @moduledoc """
  Utilities for validating JSON data.
  """

  @doc """
  Validates that a string is valid JSON.

  Returns true if the string is valid JSON, false otherwise.
  """
  @spec valid_json?(String.t()) :: boolean()
  def valid_json?(string) when is_binary(string) and string != "" do
    case Jason.decode(string) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  def valid_json?(_), do: false

  @doc """
  Validates that a field contains valid JSON in an Ecto changeset.
  Skips validation if the field is nil or empty string.
  """
  @spec validate_json(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_json(changeset, field) do
    import Ecto.Changeset, only: [get_change: 2, add_error: 3]

    payload = get_change(changeset, field)

    if is_nil(payload) or payload == "" do
      changeset
    else
      try do
        Jason.decode!(payload)
        changeset
      rescue
        error in Jason.DecodeError ->
          error_message = Exception.message(error)
          add_error(changeset, field, "is not valid JSON: #{error_message}")
      end
    end
  end
end

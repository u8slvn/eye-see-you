defmodule EyeSeeYou.Email do
   @moduledoc """
  Email notification functionality for website changes.
  """
  require Logger

  def send_change_notification(url, old_hash, new_hash) do
    subject = "EyeSeeYou: Change detected on #{get_domain(url)}"

    body = """
    EyeSeeYou has detected a change on the website you're monitoring:

    URL: #{url}
    Time: #{DateTime.utc_now() |> DateTime.to_string()}

    Details:
    • Old hash: #{String.slice(old_hash, 0, 12)}...
    • New hash: #{String.slice(new_hash, 0, 12)}...

    EyeSeeYou
    """

    send_email(subject, body)
  end

  def send_error_notification(url, reason) do
    subject = "EyeSeeYou: Error monitoring #{get_domain(url)}"

    body = """
    EyeSeeYou encountered an error while monitoring:

    URL: #{url}
    Time: #{DateTime.utc_now() |> DateTime.to_string()}
    Error: #{reason}

    Please check the website availability.

    EyeSeeYou
    """

    send_email(subject, body)
  end

  defp send_email(subject, body) do
    config = get_email_config()

    case :gen_smtp_client.send_blocking(
           {
             config.from,
             [config.to],
             "Subject: #{subject}\r\nFrom: #{config.from}\r\nTo: #{config.to}\r\n\r\n#{body}"
           },
           [
             {:relay, config.server},
             {:port, config.port},
             {:username, config.username},
             {:password, config.password},
             {:tls, :always}
           ]
         ) do
      {:ok, _} ->
        Logger.info("Notification sent successfully")
        :ok

      {:error, reason} ->
        Logger.error("Failed to send email: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_email_config do
    %{
      server: System.get_env("SMTP_SERVER") |> String.to_charlist(),
      port: String.to_integer(System.get_env("SMTP_PORT", "587")),
      username: System.get_env("EMAIL_USER") |> String.to_charlist(),
      password: System.get_env("EMAIL_PASSWORD") |> String.to_charlist(),
      from: System.get_env("EMAIL_USER"),
      to: System.get_env("RECIPIENT_EMAIL")
    }
  end

  defp get_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> "unknown"
    end
  end
end

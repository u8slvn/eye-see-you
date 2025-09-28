defmodule EyeSeeYou.Email do
  @moduledoc """
  Email notification functionality for website changes.
  """

  require Logger

  def send_change_notification(url, old_hash, new_hash) do
    Logger.info("Sending change notification for #{url}")

    recipient = System.get_env("RECIPIENT_EMAIL")
    sender_email = System.get_env("EMAIL_USER")
    password = System.get_env("EMAIL_PASSWORD")
    smtp_server = System.get_env("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = System.get_env("SMTP_PORT", "587") |> String.to_integer()

    Logger.info(
      "Email config - Server: '#{smtp_server}', Port: #{smtp_port}, From: #{sender_email}, To: #{recipient}"
    )

    cond do
      is_nil(recipient) or recipient == "" ->
        Logger.error("RECIPIENT_EMAIL not configured")

      is_nil(sender_email) or sender_email == "" ->
        Logger.error("EMAIL_USER not configured")

      is_nil(password) or password == "" ->
        Logger.error("EMAIL_PASSWORD not configured")

      true ->
        send_email_internal(
          url,
          old_hash,
          new_hash,
          smtp_server,
          smtp_port,
          sender_email,
          password,
          recipient
        )
    end
  end

  defp send_email_internal(
         url,
         old_hash,
         new_hash,
         smtp_server,
         smtp_port,
         sender_email,
         password,
         recipient
       ) do
    subject = "EyeSeeYou - Website Change Detected: #{url}"

    body = """
    A change has been detected on the website: #{url}

    Old hash: #{old_hash}
    New hash: #{new_hash}

    Time: #{DateTime.utc_now() |> DateTime.to_string()}
    """

    email = {
      sender_email,
      [recipient],
      "Subject: #{subject}\r\nFrom: #{sender_email}\r\nTo: #{recipient}\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n#{body}"
    }

    smtp_options = [
      relay: smtp_server,
      port: smtp_port,
      username: sender_email,
      password: password,
      tls: :always,
      auth: :always,
      ssl: false,
      tls_options: [
        verify: :verify_none,
        versions: [:"tlsv1.2", :"tlsv1.3"]
      ]
    ]

    try do
      Logger.info("Attempting to send email")

      result = :gen_smtp_client.send_blocking(email, smtp_options)

      case result do
        {:ok, receipt} ->
          Logger.info("Email sent successfully! Receipt: #{inspect(receipt)}")

        {:error, reason} ->
          Logger.error("SMTP error: #{inspect(reason)}")

        other when is_binary(other) ->
          if String.contains?(other, "2.0.0 OK") do
            Logger.info("Email sent successfully! Gmail response: #{other}")
          else
            Logger.error("Unexpected SMTP result: #{inspect(other)}")
          end

        other ->
          Logger.error("Unexpected SMTP result: #{inspect(other)}")
      end
    rescue
      error ->
        Logger.error("Exception sending email: #{inspect(error)}")
    end
  end
end

defmodule EyeSeeYou.Sentinels.Protoccols.HttpProtocolTest do
  use ExUnit.Case, async: false
  import Mock

  alias EyeSeeYou.Sentinels.Protoccols.HttpProtocol

  describe "perform_check/1" do
    test "successful HTTP request" do
      http_response = %HTTPoison.Response{
        status_code: 200,
        body: "OK",
        headers: []
      }

      config = build_protocol_config("GET", "https://example.com", 200)

      with_mock HTTPoison, get: fn _url, _headers, _options -> {:ok, http_response} end do
        result = HttpProtocol.perform_check(config)

        assert result.status_code == 200
        assert result.body == "OK"
        assert result.error == nil
        assert is_integer(result.duration_ms)
        assert %DateTime{} = result.timestamp
      end
    end

    test "failed HTTP request" do
      config = build_protocol_config("GET", "https://non-existent-domain.example", 200)

      with_mock HTTPoison,
        get: fn _url, _headers, _options ->
          {:error, %{reason: "connection_refused"}}
        end do
        result = HttpProtocol.perform_check(config)

        assert result.status_code == nil
        assert result.body == nil
        assert result.error == "connection_refused"
        assert is_integer(result.duration_ms)
        assert %DateTime{} = result.timestamp
      end
    end

    test "HTTP request with exception" do
      config = build_protocol_config("GET", "https://example.com", 200)

      with_mock HTTPoison,
        get: fn _url, _headers, _options ->
          raise "Timeout error"
        end do
        result = HttpProtocol.perform_check(config)

        assert result.status_code == nil
        assert result.body == nil
        assert result.error == "Timeout error"
        assert is_integer(result.duration_ms)
        assert %DateTime{} = result.timestamp
      end
    end

    test "POST request" do
      http_response = %HTTPoison.Response{
        status_code: 201,
        body: "{\"id\": 123}",
        headers: []
      }

      config = build_protocol_config("POST", "https://example.com/api", 201, "data=test")

      with_mock HTTPoison, post: fn _url, _body, _headers, _options -> {:ok, http_response} end do
        result = HttpProtocol.perform_check(config)

        assert result.status_code == 201
        assert result.body == "{\"id\": 123}"
        assert result.error == nil
      end
    end

    test "handles custom headers" do
      http_response = %HTTPoison.Response{
        status_code: 200,
        body: "OK",
        headers: []
      }

      headers = [
        %{"name" => "Authorization", "value" => "Bearer token123"},
        %{"name" => "Content-Type", "value" => "application/json"}
      ]

      config = build_protocol_config("GET", "https://example.com", 200, nil, headers)

      with_mock HTTPoison,
        get: fn _url, headers, _options ->
          assert {"Authorization", "Bearer token123"} in headers
          assert {"Content-Type", "application/json"} in headers
          {:ok, http_response}
        end do
        HttpProtocol.perform_check(config)
      end
    end
  end

  describe "check_success?/2" do
    test "returns true when status code matches expected status" do
      config = build_protocol_config("GET", "https://example.com", 200)
      result = %{status_code: 200}

      assert HttpProtocol.check_success?(result, config) == true
    end

    test "returns false when status code doesn't match expected status" do
      config = build_protocol_config("GET", "https://example.com", 200)
      result = %{status_code: 404}

      assert HttpProtocol.check_success?(result, config) == false
    end

    test "returns false when status code is nil (request failed)" do
      config = build_protocol_config("GET", "https://example.com", 200)
      result = %{status_code: nil}

      assert HttpProtocol.check_success?(result, config) == false
    end
  end

  # Helper functions
  defp build_protocol_config(method, url, expected_status, payload \\ nil, headers \\ []) do
    config = %{
      method: method,
      url: url,
      payload: payload,
      headers: headers,
      expected_status: expected_status
    }

    %{
      type: "http_request",
      config: struct(EyeSeeYou.Sentinels.Models.ProtocolConfig.HttpRequest, config)
    }
  end
end

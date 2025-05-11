defmodule EyeSeeYou.Sentinels.Protocols.SentinelProtocol do
  @moduledoc """
  Define how different types of sentinels should perform their checks.
  """

  @callback perform_check(config :: map) :: map()
  @callback check_success?(result :: map, config :: map) :: boolean()
end

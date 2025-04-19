defmodule EyeSeeYouWeb.ErrorJSONTest do
  use EyeSeeYouWeb.ConnCase, async: true

  test "renders 404" do
    assert EyeSeeYouWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert EyeSeeYouWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end

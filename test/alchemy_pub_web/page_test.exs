defmodule AlchemyPubWeb.PageTest do
  use AlchemyPubWeb.ConnCase

  test "home page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to AlchemyPub"
  end

  test "plain text pages", %{conn: conn} do
    conn = get(conn, ~p"/plain-text")
    assert html_response(conn, 200) =~ "This page is plain text."
  end

  test "access by date only", %{conn: conn} do
    conn = get(conn, ~p"/1845-01-29")
    assert html_response(conn, 200) =~ "The Raven"
  end

  test "tags", %{conn: conn} do
    conn = get(conn, ~p"/tag/poetry")
    assert html_response(conn, 200) =~ "1845-01-29: The Raven"
  end

  test "not found", %{conn: conn} do
    conn = get(conn, ~p"/not-found")
    assert html_response(conn, 200) =~ "Nothing here"
  end
end

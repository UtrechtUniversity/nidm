defmodule NidmWeb.RiskView do
    use NidmWeb, :view

    def card(header, contents) do
        assigns = %{ header: header, contents: contents }
        ~L"""
        <div class="card">
            <div class="card-header"><%= header %></div>
            <div class="card-main">
                <div class="main-description"><%= contents %></div>
            </div>
        </div>
        """
    end
end

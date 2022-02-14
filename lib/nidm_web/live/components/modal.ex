defmodule NidmWeb.Components.Modal do
    use NidmWeb, :live_component

    @impl true
    def mount(socket) do
        { :ok, assign(socket, state: :closed) }
    end

    @impl true
    def update(assigns, socket) do
        { :ok, socket |> assign(assigns) }
    end

    @impl true
    def handle_event("open-modal", _, socket) do
        { :noreply, assign(socket, :state, :open) }
    end

    @impl true
    def handle_event("close-modal", _, socket) do
        {:noreply, assign(socket, :state, :closed)}
    end

end

defmodule MailgunLoggerWeb.Components.Flop do
  @moduledoc "Flop related UI"

  import Flop.Phoenix

  use MailgunLoggerWeb, :component

  alias MailgunLoggerWeb.CoreComponents

  def pagination_opts do
    [
      # <ul> tag
      pagination_list_attrs: [class: "pagination"],
      # <a> in <li>
      pagination_link_attrs: [class: "page-link"],
      current_link_attrs: [class: "page-link active"],
      page_links: :all,
      ellipsis_content: "  ‥  ",
      next_link_content: ">>",
      previous_link_content: "<<",
      previous_link_attrs: [
        class: "page-link"
      ],
      next_link_attrs: [
        class: "page-link"
      ]
    ]
  end

  def events_filter_form(%{meta: meta} = assigns) do
    message_id = Enum.find_value(meta.flop.filters, &(&1.field == :message_id && &1.value))
    assigns = assign(assigns, form: Phoenix.Component.to_form(meta), message_id: message_id)

    ~H"""
    <.form for={@form} id={@id}>
      <%!-- The message filter has no input; keep it when the form is sent --%>
      <input :if={@message_id} type="hidden" name="filters[99][field]" value="message_id" />
      <input :if={@message_id} type="hidden" name="filters[99][op]" value="==" />
      <input :if={@message_id} type="hidden" name="filters[99][value]" value={@message_id} />
      <.filter_fields
        :let={i}
        form={@form}
        fields={[
          event: [
            type: "select",
            options: [{"all", ""}] ++ ~w(delivered accepted opened failed stored)
          ],
          message_from: [op: :ilike, placeholder: "From"],
          recipient: [op: :ilike, placeholder: "Recipient"],
          message_subject: [op: :ilike, placeholder: "Subject"],
          account_id: [type: "select", options: [{"all", ""}] ++ @accounts],
          timestamp: [op: :>=, type: "datetime-local", label: "Since", title: "Since (UTC)"],
          timestamp: [op: :<=, type: "datetime-local", label: "Until", title: "Until (UTC)"]
        ]}
      >
        <CoreComponents.input
          field={i.field}
          label={i.label}
          type={i.type}
          phx-debounce={120}
          {i.rest}
        />
      </.filter_fields>
      <CoreComponents.button>Search</CoreComponents.button>
    </.form>
    """
  end
end

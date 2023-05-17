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
    assigns = assign(assigns, :form, Phoenix.Component.to_form(meta))

    ~H"""
    <.form for={@form} class="flex-1 py-2 pr-4 h-full" id={@id}>
      <.filter_fields
        :let={i}
        form={@form}
        fields={ 
        [
          message_from: [op: :ilike, placeholder: "From"],
          recipient: [op: :ilike, placeholder: "Recipient"],
          message_subject: [op: :ilike, placeholder: "subject"],
          account_domain: [type: "select", options: @accounts]
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

# <%= text_input f, :subject, placeholder: "Subject" %>
# <%= text_input f, :recipient, placeholder: "Recipient" %>
# <%= text_input f, :from, placeholder: "From" %>

# <%= checkbox f, :delivered %>
# <%= label f, :delivered %>
# <%= error_tag f, :delivered %>

# <%= checkbox f, :accepted %>
# <%= label f, :accepted %>
# <%= error_tag f, :accepted %>

# <%= checkbox f, :opened %>
# <%= label f, :opened %>
# <%= error_tag f, :opened %>

# <%= checkbox f, :failed %>
# <%= label f, :failed %>
# <%= error_tag f, :failed %>

# <%= checkbox f, :stored %>
# <%= label f, :stored %>
# <%= error_tag f, :stored %>

# <%= select(f, :account, cbo_accounts(@accounts)) %>

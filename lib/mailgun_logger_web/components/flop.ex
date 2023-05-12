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

  def filter_form(%{meta: meta} = assigns) do
    assigns = assign(assigns, :form, Phoenix.Component.to_form(meta))

    # The 'searchable' field in this form maps on the compound Flop field defined in lib/justified/partners/repos/partner.ex
    # The compound field contains the name of the partner and the name of the partner's users.
    ~H"""
    <.form for={@form} class="flex-1 py-2 pr-4 h-full">
      frm
      <.filter_fields
        :let={f}
        form={@form}
        fields={[
          searchable: [
            label: "searchable",
            op: :like,
            placeholder: assigns[:search_placeholder] || "Search",
            autofocus: true
          ]
        ]}
      >
        filter
        <br />
        <input type="text" name={f.field.name} id={f.field.id} value={f.field.value} {f.rest} />

        <CoreComponents.input field={@form[:subject]} label="Email"/>


          <CoreComponents.button>Search</CoreComponents.button>

      </.filter_fields>
    </.form>
    """
  end

  def filter_form_actions(%{meta: meta} = assigns) do
    assigns = assign(assigns, :form, Phoenix.Component.to_form(meta))

    # The 'searchable' field in this form maps on the compound Flop field defined in lib/justified/partners/repos/partner.ex
    # The compound field contains the name of the partner and the name of the partner's users.
    ~H"""
    <.form for={@form} class="searchbox pr-1" method="get">
      <input name="type" type="hidden" value={@type} />

      <.filter_fields
        :let={i}
        form={@form}
        fields={[
          searchable: [
            class: "border-0",
            label: "searchable",
            op: :like,
            placeholder: "Zoekterm...",
            autofocus: true,
            autocomplete: "off",
            tabindex: 0
          ]
        ]}
      >
        <br />
        <input type="search" name={i.field.name} id={i.field.id} value={i.field.value} {i.rest} />
      </.filter_fields>

      <label class="searchbox-icon" for="search">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 451 451">
          <path d="M447.05 428l-109.6-109.6c29.4-33.8 47.2-77.9 47.2-126.1C384.65 86.2 298.35 0 192.35 0 86.25 0 .05 86.3.05 192.3s86.3 192.3 192.3 192.3c48.2 0 92.3-17.8 126.1-47.2L428.05 447c2.6 2.6 6.1 4 9.5 4s6.9-1.3 9.5-4c5.2-5.2 5.2-13.8 0-19zM26.95 192.3c0-91.2 74.2-165.3 165.3-165.3 91.2 0 165.3 74.2 165.3 165.3s-74.1 165.4-165.3 165.4c-91.1 0-165.3-74.2-165.3-165.4z">
          </path>
        </svg>
      </label>
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

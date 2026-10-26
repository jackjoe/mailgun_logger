"use strict";
(function () {
  function buildHiddenInput(name, value) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }

  function handleLinkClick(link) {
    var message = link.getAttribute("data-confirm");
    if (message && !window.confirm(message)) {
      return;
    }

    var to = link.getAttribute("data-to"),
      method = buildHiddenInput("_method", link.getAttribute("data-method")),
      csrf = buildHiddenInput("_csrf_token", link.getAttribute("data-csrf")),
      form = document.createElement("form"),
      target = link.getAttribute("target");

    form.method = link.getAttribute("data-method") === "get" ? "get" : "post";
    form.action = to;
    form.style.display = "hidden";

    if (target) form.target = target;

    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);
    form.submit();
  }

  window.addEventListener(
    "click",
    function (e) {
      var element = e.target;

      while (element && element.getAttribute) {
        if (element.getAttribute("data-method")) {
          handleLinkClick(element);
          e.preventDefault();
          return false;
        } else {
          element = element.parentNode;
        }
      }
    },
    false
  );

  var modalButtons = document.querySelectorAll("[data-toggle='modal']");
  Array.prototype.slice.call(modalButtons).forEach((el) => {
    var target = document.querySelector(el.dataset.target);
    if (target) {
      el.addEventListener("click", function (e) {
        e.preventDefault();
        target.classList.toggle("show");
        target.querySelector(".close").focus();
      });
    }
  });
  var modals = document.querySelectorAll(".modal");
  Array.prototype.slice.call(modals).forEach(function (modal) {
    var id = modal.getAttribute("id");
    modal
      .querySelector("[data-dismiss='modal']")
      .addEventListener("click", function () {
        var modal = document.querySelector(`#${id}`);
        modal.classList.toggle("show");
      });
  });
})();

// Keyboard shortcuts on the events list: "/" focuses the search, "j" and "k"
// move between rows, Enter opens the selected event and Escape leaves a field.
(function () {
  if (!document.querySelector(".log-table")) return;

  var current = -1;

  function rows() {
    return Array.prototype.slice.call(document.querySelectorAll(".log-row"));
  }

  function select(index) {
    var list = rows();
    if (list.length === 0) return;

    current = Math.max(0, Math.min(index, list.length - 1));
    list.forEach(function (row, i) {
      row.classList.toggle("is-selected", i === current);
    });
    list[current].scrollIntoView({ block: "nearest" });
  }

  function isTyping(element) {
    return (
      element &&
      (["INPUT", "SELECT", "TEXTAREA"].indexOf(element.tagName) !== -1 ||
        element.isContentEditable)
    );
  }

  document.addEventListener("keydown", function (e) {
    if (e.ctrlKey || e.metaKey || e.altKey) return;

    if (isTyping(e.target)) {
      if (e.key === "Escape") e.target.blur();
      return;
    }

    if (e.key === "/") {
      var search = document.querySelector("#events-filter input[type='text']");
      if (search) {
        e.preventDefault();
        search.focus();
      }
    } else if (e.key === "j") {
      select(current + 1);
    } else if (e.key === "k") {
      select(current - 1);
    } else if (e.key === "Enter" && current >= 0) {
      var detail = rows()[current].querySelector(".log-col-actions a:last-child");
      if (detail) window.location.href = detail.href;
    }
  });
})();

// A button with data-copy="#id" copies the text of that element.
(function () {
  document.addEventListener("click", function (e) {
    var button = e.target.closest("[data-copy]");
    if (!button || !navigator.clipboard) return;

    var target = document.querySelector(button.getAttribute("data-copy"));
    if (!target) return;

    navigator.clipboard.writeText(target.textContent.trim()).then(function () {
      var label = button.textContent;
      button.textContent = "Copied";
      setTimeout(function () {
        button.textContent = label;
      }, 1500);
    });
  });
})();

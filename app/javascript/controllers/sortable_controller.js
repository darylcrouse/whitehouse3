import { Controller } from "@hotwired/stimulus"

// Drag-to-reorder for the user's ranked priority list. On drop it POSTs the new
// order of endorsement ids back to the server. Degrades gracefully: if JS is off,
// the list still renders (just not reorderable).
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.dragged = null
    this.element.querySelectorAll("[data-sortable-item]").forEach((li) => {
      li.setAttribute("draggable", "true")
      li.addEventListener("dragstart", (e) => this.start(e, li))
      li.addEventListener("dragover", (e) => this.over(e, li))
      li.addEventListener("dragend", () => this.end(li))
      li.addEventListener("drop", (e) => e.preventDefault())
    })
  }

  start(e, li) {
    this.dragged = li
    li.classList.add("dragging")
  }

  over(e, li) {
    e.preventDefault()
    if (!this.dragged || this.dragged === li) return
    const rect = li.getBoundingClientRect()
    const after = (e.clientY - rect.top) / rect.height > 0.5
    if (after) {
      li.after(this.dragged)
    } else {
      li.before(this.dragged)
    }
  }

  end(li) {
    li.classList.remove("dragging")
    this.save()
  }

  save() {
    const ids = Array.from(this.element.querySelectorAll("[data-sortable-item]"))
      .map((el) => el.dataset.id)
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "application/json" },
      body: JSON.stringify({ endorsement_ids: ids })
    }).then(() => {
      this.element.querySelectorAll("[data-rank]").forEach((el, i) => { el.textContent = i + 1 })
    })
  }
}

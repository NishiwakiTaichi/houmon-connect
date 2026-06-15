import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "hourlyFields", "slotList", "slotTemplate"]

  connect() {
    this.toggleHourly()
  }

  toggleHourly() {
    const isHourly = this.typeSelectTarget.value === "hourly"
    this.hourlyFieldsTarget.classList.toggle("d-none", !isHourly)
  }

  addSlot() {
    const clone = this.slotTemplateTarget.content.cloneNode(true)
    this.slotListTarget.appendChild(clone)
  }

  removeSlot(event) {
    event.currentTarget.closest("[data-slot]").remove()
  }
}

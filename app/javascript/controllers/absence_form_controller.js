import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "hourlyFields"]

  connect() {
    this.toggleHourly()
  }

  toggleHourly() {
    const isHourly = this.typeSelectTarget.value === "hourly"
    this.hourlyFieldsTarget.classList.toggle("d-none", !isHourly)
  }
}

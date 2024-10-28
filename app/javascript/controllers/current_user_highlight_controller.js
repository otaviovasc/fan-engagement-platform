// app/javascript/controllers/current_user_highlight_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Current user highlight controller connected")


    this.userEntry = document.getElementById("current-user-entry")
    this.fixedCard = this.element.querySelector(".fixed-user-card")
    console.log("Current user entry:", this.userEntry);
    console.log("Fixed card entry:", this.fixedCard);


    if (this.userEntry && this.fixedCard) {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (!entry.isIntersecting) {
            // When the user entry is out of the viewport, show the fixed card
            this.fixedCard.classList.remove("d-none")
          } else {
            // When the user entry is in the viewport, hide the fixed card
            this.fixedCard.classList.add("d-none")
          }
        })
      }, {
        root: null, // default to the viewport
        threshold: 0.1
      })

      // Observe the user entry
      observer.observe(this.userEntry)
    } else if (this.fixedCard) {
      // If user is not in the leaderboard, always show the fixed card
      this.fixedCard.classList.remove("d-none")
    }
  }
}

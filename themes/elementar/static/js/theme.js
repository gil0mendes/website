function initTheme() {
  const styleDarkEl = document.getElementById("style-dark");
  const styleLightEl = document.getElementById("style-light");

  function setStyle(isDarkTheme) {
    const newValue = !!isDarkTheme;

    styleDarkEl.disabled = newValue;
    styleLightEl.disabled = !newValue;

    localStorage.setItem("theme-dark", newValue ? "1" : "");
  }

  // initalize store at the first time
  setStyle(localStorage.getItem("theme-dark"));

  document.querySelector(".theme-toggle").addEventListener("click", () => {
    setStyle(!styleDarkEl.disabled);
  });

  // CSS transitions are blocked on load, unblock when ready
  document.body.classList.remove("notransition");
}

window.addEventListener("DOMContentLoaded", initTheme);

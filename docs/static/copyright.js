document$.subscribe(function initCopyrightYear() {
  var currentYear = new Date().getFullYear();
  var yearSpan = document.getElementById("current-year-9b1a4d19");
  yearSpan.innerHTML = `${currentYear} `;
});

document$.subscribe(function popUpModal() {
  const modal = document.getElementById("modal");
  const closeButton = document.querySelector(".close-button");

  function showModal() {
    modal.style.display = "flex";
  }

  closeButton.addEventListener("click", function closeSubscribeModal() {
    modal.style.display = "none";
    localStorage.setItem("subscribed", true);
  });

  if (localStorage.getItem("subscribed") != "true") {
    setTimeout(showModal, 1);
  }
});

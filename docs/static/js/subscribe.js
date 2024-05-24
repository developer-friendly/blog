const subscribeModalKey = "subscribe-modal";
const subscribeEmailkey = "subscribe-email";

document$.subscribe(function popUpModal() {
  var email;
  var modal = document.getElementById("modal");
  var closeButton = document.querySelector(".close-button");
  var subscribeForm = document.getElementById("subscribe-form");

  subscribeForm.addEventListener("submit", function subscribe(event) {
    event.preventDefault();

    var formData = new FormData(event.target);
    email = formData.get("email");

    if (email) {
      localStorage.setItem(subscribeEmailkey, email);
    }

    if (email && window.LogRocket) {
      window.LogRocket.identify(email);
    }

    localStorage.setItem(subscribeModalKey, true);

    event.target.submit();
  });

  email = localStorage.getItem(subscribeEmailkey);
  if (email && window.LogRocket) {
    window.LogRocket.identify(email);
  }

  function showModal() {
    modal.style.display = "flex";
  }

  closeButton.addEventListener("click", function closeSubscribeModal() {
    modal.style.display = "none";
    localStorage.setItem(subscribeModalKey, true);
  });

  // TODO: uncomment when newsletter is ready
  // if (localStorage.getItem(subscribeModalKey) != "true") {
  //   setTimeout(showModal, 5000);
  // }
});

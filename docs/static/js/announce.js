function shuffle(array) {
  var currentIndex = array.length,
    temporaryValue,
    randomIndex;
  while (0 != currentIndex) {
    randomIndex = Math.floor(Math.random() * currentIndex);
    currentIndex -= 1;
    temporaryValue = array[currentIndex];
    array[currentIndex] = array[randomIndex];
    array[randomIndex] = temporaryValue;
  }
  return array;
}

function showRandomAnnouncement(groupId, timeInterval) {
  var announcement = document.getElementById(groupId);
  if (announcement) {
    var children = [].slice.call(announcement.children);
    children = shuffle(children);
    var index = 0;
    function announceRandom() {
      children.forEach(function displayNone(el, i) {
        el.style.display = "none";
      });
      children[index].style.display = "block";
      index = (index + 1) % children.length;
    }
    announceRandom();
    setInterval(announceRandom, timeInterval);
  }
}

document$.subscribe(function ensureRuns() {
  showRandomAnnouncement("announce-left", 5000);
})

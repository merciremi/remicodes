const phrases = [
  "messy hair",
  "ruby on rails",
  "drinking good coffee",
  "on a long walk"
];

const el = document.querySelector(".header--typewriter");
let phraseIndex = 0;
let charIndex = 0;
let deleting = false;

function tick() {
  const phrase = phrases[phraseIndex];

  if (deleting) {
    charIndex--;
    el.textContent = phrase.slice(0, charIndex);
    if (charIndex === 0) {
      deleting = false;
      phraseIndex = (phraseIndex + 1) % phrases.length;
      setTimeout(tick, 400);
      return;
    }
    setTimeout(tick, 40);
  } else {
    charIndex++;
    el.textContent = phrase.slice(0, charIndex);
    if (charIndex === phrase.length) {
      deleting = true;
      setTimeout(tick, 1800);
      return;
    }
    setTimeout(tick, 80);
  }
}

tick();

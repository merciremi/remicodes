document.addEventListener('DOMContentLoaded', () => {
  const brightColors = [
    '#FF0000', '#00CC00', '#0055FF', '#FF6600', '#FF00CC', '#9900FF'
  ];


  const spans = document.querySelectorAll('.color-shuffle span');

  spans.forEach(span => {
    span.addEventListener('mouseenter', () => {
      if (span.textContent.trim()) {
        const randomColor = brightColors[Math.floor(Math.random() * brightColors.length)];
        span.style.color = randomColor;
        span.classList.add('wobbling');
      }
    });

    span.addEventListener('mouseleave', () => {
      span.style.color = '';
    });

    span.addEventListener('animationend', () => {
      span.classList.remove('wobbling');
    });
  });
});

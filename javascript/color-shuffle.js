document.addEventListener('DOMContentLoaded', () => {
  const brightColors = [
    '#e2242a', '#f05032', '#FF4500', '#00FF7F', '#FF69B4', '#4169E1', '#FFFF00', "#9370DB"
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

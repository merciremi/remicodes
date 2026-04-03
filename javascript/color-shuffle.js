document.addEventListener('DOMContentLoaded', () => {
  const brightColors = [
    '#FF0000', '#FF8C00', '#FFD700', '#00FF00', '#00CED1',
    '#0000FF', '#FF69B4', '#FF1493', '#00BFFF', '#ADFF2F'
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

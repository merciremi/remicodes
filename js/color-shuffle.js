document.addEventListener('DOMContentLoaded', () => {
  const brightColors = [
    '#FF3D56', '#FF6B35', '#F7C731', '#7ED321', '#00D4AA',
    '#00BFFF', '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16'
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

// ===== Reproductor de radio =====
const audio = document.getElementById('radioStream');
const playButton = document.getElementById('playButton');
const playIcon = playButton.querySelector('.icon--play');
const pauseIcon = playButton.querySelector('.icon--pause');
const statusEl = document.getElementById('playerStatus');
const liveDot = statusEl.querySelector('.live-dot');

let isPlaying = false;

function setPlayingUI(playing){
  isPlaying = playing;
  playIcon.hidden = playing;
  pauseIcon.hidden = !playing;
  liveDot.classList.toggle('is-live', playing);
  statusEl.lastChild.textContent = playing ? ' En vivo ahora' : ' Presioná play para escuchar';
  playButton.setAttribute('aria-label', playing ? 'Pausar Eco Celestial' : 'Reproducir Eco Celestial en vivo');
}

playButton.addEventListener('click', () => {
  if (isPlaying) {
    audio.pause();
    setPlayingUI(false);
  } else {
    statusEl.lastChild.textContent = ' Conectando…';
    audio.play()
      .then(() => setPlayingUI(true))
      .catch(() => {
        statusEl.lastChild.textContent = ' No se pudo conectar con la transmisión';
      });
  }
});

audio.addEventListener('waiting', () => {
  if (isPlaying) statusEl.lastChild.textContent = ' Conectando…';
});
audio.addEventListener('playing', () => {
  if (isPlaying) statusEl.lastChild.textContent = ' En vivo ahora';
});

// ===== Portal de noticias =====
const newsGrid = document.getElementById('newsGrid');
const newsEmpty = document.getElementById('newsEmpty');
const newsUpdated = document.getElementById('newsUpdated');

function formatDate(iso){
  try {
    const date = new Date(iso);
    return date.toLocaleString('es-AR', {
      day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit'
    });
  } catch (e) {
    return '';
  }
}

function renderNews(data){
  const items = data.items || [];

  if (data.generated_at) {
    newsUpdated.textContent = `Última actualización: ${formatDate(data.generated_at)}`;
  }

  if (!items.length) {
    newsEmpty.hidden = false;
    return;
  }

  newsGrid.innerHTML = items.map(item => `
    <article class="news-card" data-category="${escapeHtml(item.category || '')}">
      <p class="news-card__meta">
        <span class="news-card__source">${escapeHtml(item.source_name || '')}</span>
        <span>·</span>
        <span>${formatDate(item.published)}</span>
      </p>
      <h3 class="news-card__title">
        <a href="${escapeHtml(item.link)}" target="_blank" rel="noopener noreferrer">
          ${escapeHtml(item.title)}
        </a>
      </h3>
      ${item.summary ? `<p class="news-card__summary">${escapeHtml(item.summary)}</p>` : ''}
      <a class="news-card__link" href="${escapeHtml(item.link)}" target="_blank" rel="noopener noreferrer">
        Leer en el sitio oficial
      </a>
    </article>
  `).join('');
}

function escapeHtml(str){
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

fetch('data/news.json', { cache: 'no-store' })
  .then(res => {
    if (!res.ok) throw new Error('No se pudo cargar news.json');
    return res.json();
  })
  .then(renderNews)
  .catch(() => {
    newsEmpty.hidden = false;
  });

'use strict';
const search = document.querySelector('#operator-search');
const operators = [...document.querySelectorAll('#operator-list li')];
const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/ø/g, 'o').toLowerCase();
search.addEventListener('input', () => {
  const query = normalize(search.value.trim());
  let shown = 0;
  for (const item of operators) {
    item.hidden = !normalize(item.dataset.search).includes(query);
    if (!item.hidden) shown++;
  }
  document.querySelector('#roster-count').textContent = query ? `${shown} of ${operators.length} operators` : `${operators.length} operators`;
  document.querySelector('#empty-roster').hidden = shown !== 0;
});
document.querySelector('#copy-hash').addEventListener('click', async event => {
  const button = event.currentTarget;
  const checksum = document.querySelector('#checksum');
  try {
    await navigator.clipboard.writeText(checksum.textContent.trim());
    button.textContent = 'Checksum copied ✓';
    document.querySelector('#copy-status').textContent = 'SHA-256 checksum copied to clipboard.';
  } catch {
    const range = document.createRange();
    range.selectNodeContents(checksum);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    button.textContent = 'Selected — press Ctrl/Cmd+C';
    document.querySelector('#copy-status').textContent = 'Automatic copying unavailable. Checksum selected for manual copying.';
  }
});

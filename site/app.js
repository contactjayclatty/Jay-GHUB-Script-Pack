'use strict';

const search = document.querySelector('#operator-search');
if (search) {
  const operators = [...document.querySelectorAll('#operator-list li')];
  const normalize = value => value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/ø/g, 'o');
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
}

document.querySelector('#copy-hash')?.addEventListener('click', async event => {
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

const dialog = document.querySelector('#download-dialog');
if (dialog && window.fetch && window.crypto?.subtle && typeof dialog.showModal === 'function') {
  const title = document.querySelector('#transfer-title');
  const status = document.querySelector('#transfer-status');
  const progress = document.querySelector('#transfer-progress');
  const amount = document.querySelector('#transfer-amount');
  const percent = document.querySelector('#transfer-percent');
  const save = document.querySelector('#save-transfer');
  const retry = document.querySelector('#retry-transfer');
  const cancel = document.querySelector('#cancel-transfer');
  const fallback = document.querySelector('#transfer-fallback');
  let controller;
  let objectUrl;
  let currentFile;
  let activeLink;
  let generation = 0;
  const size = bytes => `${(bytes / 1024).toFixed(1)} KB`;

  function releaseBlob() {
    if (objectUrl) URL.revokeObjectURL(objectUrl);
    objectUrl = undefined;
  }

  function stop() {
    generation++;
    controller?.abort();
    releaseBlob();
  }

  function close() {
    stop();
    dialog.close();
    activeLink?.focus();
  }

  async function start(link) {
    stop();
    const thisGeneration = generation;
    activeLink = link;
    controller = new AbortController();
    const signal = controller.signal;
    save.hidden = true;
    retry.hidden = true;
    cancel.hidden = false;
    progress.hidden = false;
    progress.removeAttribute('value');
    amount.textContent = 'Connecting…';
    percent.textContent = '—';
    title.textContent = 'Preparing your file.';
    status.textContent = 'Connecting to the download server.';
    document.querySelector('#transfer-file').textContent = link.getAttribute('download');
    fallback.href = `https://github.com/contactjayclatty/Jay-GHUB-Script-Pack/releases/download/v1.2.0/${link.getAttribute('download')}`;
    if (!dialog.open) dialog.showModal();
    document.querySelector('#close-transfer').focus();
    try {
      const metadataResponse = await fetch('downloads/release.json', { signal });
      if (!metadataResponse.ok) throw new Error('Release information could not be loaded.');
      const metadata = await metadataResponse.json();
      const file = metadata[link.dataset.download];
      if (!file || file.size > 50 * 1024 * 1024 || !/^[a-f0-9]{64}$/.test(file.sha256)) throw new Error('Release information is invalid.');
      currentFile = file;
      fallback.href = file.github;
      title.textContent = 'Receiving your file.';
      status.textContent = 'The progress below measures bytes received.';
      const response = await fetch(file.url, { signal });
      if (!response.ok) throw new Error(`The server returned HTTP ${response.status}.`);
      let data;
      if (response.body?.getReader) {
        const reader = response.body.getReader();
        const chunks = [];
        let received = 0;
        progress.max = file.size;
        progress.value = 0;
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          received += value.byteLength;
          if (received > file.size) throw new Error('The received file is larger than expected.');
          chunks.push(value);
          if (thisGeneration !== generation) return;
          progress.value = received;
          amount.textContent = `${size(received)} / ${size(file.size)}`;
          percent.textContent = `${Math.floor(received / file.size * 100)}%`;
        }
        data = new Uint8Array(received);
        let offset = 0;
        for (const chunk of chunks) { data.set(chunk, offset); offset += chunk.byteLength; }
      } else {
        status.textContent = 'Receiving the file. This browser does not expose byte-by-byte progress.';
        data = new Uint8Array(await response.arrayBuffer());
      }
      if (thisGeneration !== generation) return;
      if (data.byteLength !== file.size) throw new Error('The transfer ended before the full file arrived.');
      title.textContent = 'Checking the file.';
      status.textContent = 'Comparing SHA-256 with the published release.';
      const digest = await crypto.subtle.digest('SHA-256', data);
      const hash = [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
      if (thisGeneration !== generation) return;
      if (hash !== file.sha256) throw new Error('Checksum mismatch. The file will not be offered for saving.');
      objectUrl = URL.createObjectURL(new Blob([data], { type: 'application/octet-stream' }));
      progress.max = file.size;
      progress.value = file.size;
      amount.textContent = `${size(file.size)} / ${size(file.size)}`;
      percent.textContent = '100%';
      title.textContent = 'Verified. Ready to save.';
      status.textContent = 'File received. Its SHA-256 matches the published release. Choose Save file to send it to your browser’s download manager.';
      cancel.hidden = true;
      save.hidden = false;
      save.textContent = 'Save file ↓';
    } catch (error) {
      if (thisGeneration !== generation) return;
      releaseBlob();
      title.textContent = error.name === 'AbortError' ? 'Transfer cancelled.' : 'Download interrupted.';
      status.textContent = error.name === 'AbortError' ? 'No file was offered for saving. Try again when you’re ready.' : `${error.message} Retry, or use the direct GitHub link below.`;
      progress.removeAttribute('value');
      progress.hidden = true;
      percent.textContent = '—';
      amount.textContent = 'File not ready';
      cancel.hidden = true;
      retry.hidden = false;
    }
  }

  document.querySelectorAll('[data-download]').forEach(link => link.addEventListener('click', event => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    start(link);
  }));
  retry.addEventListener('click', () => start(activeLink));
  cancel.addEventListener('click', () => controller?.abort());
  document.querySelector('#close-transfer').addEventListener('click', close);
  dialog.addEventListener('cancel', event => { event.preventDefault(); close(); });
  dialog.addEventListener('close', stop);
  save.addEventListener('click', () => {
    if (!objectUrl) return;
    const anchor = document.createElement('a');
    anchor.href = objectUrl;
    anchor.download = currentFile.file;
    document.body.append(anchor);
    anchor.click();
    anchor.remove();
    title.textContent = 'Save requested.';
    status.textContent = 'Check your browser’s download manager for the saved file. This page cannot confirm a disk save. You can request it again below.';
    save.textContent = 'Save again ↓';
  });
  window.addEventListener('pagehide', stop);
}

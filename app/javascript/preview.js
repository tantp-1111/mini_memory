// 画像プレビューを生成して new-image コンテナに差し替える
function renderPreview(file) {
    const imageContainer = document.getElementById('new-image');
    if (!imageContainer) return;

    // 既存の img (ERB 描画/JS 追加) を全て削除して入れ替える
    imageContainer.innerHTML = '';

    const blobImage = document.createElement('img');
    blobImage.src = window.URL.createObjectURL(file);
    blobImage.dataset.jsPreview = 'true'; // JS で動的に追加した preview を識別するマーク
    blobImage.classList.add('h-full', 'w-auto', 'block', 'mx-auto', 'mt-2');
    imageContainer.appendChild(blobImage);

    const fileNameEl = document.getElementById('file-name');
    if (fileNameEl) {
        fileNameEl.textContent = file.name;
        fileNameEl.classList.remove('hidden');
    }
}

// document レベルで delegation することで、Turbo が body を置き換えた後でも
// 新しい input 要素に対して同じハンドラが有効に動く
// (turbo:load 内での addEventListener では再レンダリング後の要素を拾えないため)
document.addEventListener('change', (e) => {
    if (e.target.id !== 'memory_image') return;
    const file = e.target.files[0];
    if (!file) return;
    renderPreview(file);
});

// バックボタンキャッシュの clean up
// ERB が描画した既存画像は残し、JS で追加した preview のみクリアする
document.addEventListener('turbo:before-cache', () => {
    const previews = document.getElementById('new-image');
    if (previews) {
        previews.querySelectorAll('img[data-js-preview]').forEach((el) => el.remove());
    }
    const fileNameEl = document.getElementById('file-name');
    if (fileNameEl) {
        fileNameEl.textContent = '';
        fileNameEl.classList.add('hidden');
    }
});

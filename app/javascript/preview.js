// 直近で生成した object URL を保持し、不要になったタイミングで revoke してメモリリークを防ぐ
let currentObjectUrl = null;

function revokeCurrentObjectUrl() {
    if (currentObjectUrl) {
        URL.revokeObjectURL(currentObjectUrl);
        currentObjectUrl = null;
    }
}

// 画像プレビューを生成して new-image コンテナに差し替える
function renderPreview(file) {
    const imageContainer = document.getElementById('new-image');
    if (!imageContainer) return;

    // 既存 img (ERB 描画/JS 追加) を全て削除し、前回の object URL を解放する
    imageContainer.innerHTML = '';
    revokeCurrentObjectUrl();

    currentObjectUrl = window.URL.createObjectURL(file);

    const blobImage = document.createElement('img');
    blobImage.src = currentObjectUrl;
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
// 残っている object URL もここで revoke する
document.addEventListener('turbo:before-cache', () => {
    revokeCurrentObjectUrl();

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

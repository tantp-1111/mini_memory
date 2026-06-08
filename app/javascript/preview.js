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

// アバター画像プレビューを生成して avatar-preview コンテナに差し替える
function renderAvatarPreview(file) {
    const container = document.getElementById('avatar-preview');
    if (!container) return;

    // Turbo back キャッシュ復帰時に元の表示（添付済み画像 or placeholder）を戻せるよう原 HTML を保持
    if (!container.dataset.originalHtml) {
        container.dataset.originalHtml = container.innerHTML;
    }

    revokeCurrentObjectUrl();
    currentObjectUrl = window.URL.createObjectURL(file);

    container.innerHTML = '';

    const avatarDiv = document.createElement('div');
    avatarDiv.className = 'avatar';
    avatarDiv.dataset.jsPreview = 'true';

    const innerDiv = document.createElement('div');
    innerDiv.className = 'w-20 h-20 rounded-full overflow-hidden';

    const img = document.createElement('img');
    img.src = currentObjectUrl;
    img.alt = 'avatar preview';
    img.className = 'w-full h-full object-cover';

    innerDiv.appendChild(img);
    avatarDiv.appendChild(innerDiv);
    container.appendChild(avatarDiv);
}

document.addEventListener('change', (e) => {
    if (e.target.id !== 'user_avatar') return;
    const file = e.target.files[0];
    if (!file) return;
    renderAvatarPreview(file);
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

    // アバタープレビューは原 HTML を退避していれば戻す
    const avatarPreview = document.getElementById('avatar-preview');
    if (avatarPreview?.dataset.originalHtml) {
        avatarPreview.innerHTML = avatarPreview.dataset.originalHtml;
        delete avatarPreview.dataset.originalHtml;
    }
});

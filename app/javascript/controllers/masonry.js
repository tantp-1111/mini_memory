$(document).on("turbo:load", function () {
  const $masonry = $(".masonry");
  if ($masonry.length === 0) return; //もしmasonryクラスが見つからなければ処理を終了

  $masonry.imagesLoaded(function () { //要素内の全ての画像が読み込まれるまで待つ
    $masonry.masonry({
      itemSelector: ".masonry-item",  //どの要素を並べるかを指定
      gutter: 20,  // 各アイテム間の左右の隙間を 20px に設定
      percentPosition: true, //レスポンシブ対応のため、位置を % で計算
    });
  });
});
import React, { useEffect, useState, useCallback } from "react"

// ── ユーティリティ ──────────────────────────────
const shuffle = (arr) => [...arr].sort(() => Math.random() - 0.5)

const buildDeck = (cards) =>
  shuffle([...cards, ...cards]).map((card, index) => ({
    ...card,
    index,        // 盤面上のユニークキー
    flipped: false,
    matched: false,
  }))

// CSRFトークンを取得する関数
const getCsrfToken = () =>
  document.querySelector('meta[name="csrf-token"]')?.content ?? ""

// ── カード1枚 ───────────────────────────────────
  // アイコンのパスをdata属性から取得
const iconPath = document.getElementById("memory-game-root")?.dataset.iconPath
  // React.memoで不要な再レンダリングを防止
const Card = React.memo(({ card, onClick }) => {
  // まだめくられていない、かつマッチしていないカードのみクリック可能
  const handleClick = () => {
    if (!card.flipped && !card.matched) onClick(card.index)
  }

  return (
    // perspectiveで3D空間を作り、cursor-pointerでクリック可能、aspect-squareで正方形を維持
    <div
      className="[perspective:800px] cursor-pointer aspect-square"
      onClick={handleClick}
    >
      {/* カードの表裏を3Dで回転させる */}
      <div
        className={[
          "relative w-full h-full transition-transform duration-500 ease-in-out",
          "[transform-style:preserve-3d]",
          card.flipped || card.matched ? "[transform:rotateY(180deg)]" : "",
        ].join(" ")}
      >
        {/* 裏面 */}
        <div className="absolute inset-0 rounded-2xl bg-white flex items-center justify-center text-primary-content text-4xl select-none [backface-visibility:hidden] shadow-md">
          <img
            src={iconPath}
            alt="カード裏面"
            className="w-16 h-16 object-contain"
          />
        </div>

        {/* 表面 */}
        <div
          className={[
            "absolute inset-0 rounded-2xl overflow-hidden [backface-visibility:hidden]",
            "[transform:rotateY(180deg)] shadow-md",
            card.matched? "ring-4 ring-success ring-offset-2" : "border-2 border-base-300",
          ].join(" ")}
        >
          <img
            src={card.url}
            alt={card.title}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        </div>
      </div>
    </div>
  )
})

// ── マッチ時モーダル（投稿内容を表示）──────────
const MatchModal = ({ card, onClose }) => {
  if (!card) return null

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-md">
        {/* 画像 */}
        <div className="w-full aspect-video rounded-xl overflow-hidden mb-4">
          <img
            src={card.url}
            alt={card.title}
            className="w-full h-full object-cover"
          />
        </div>

        {/* 投稿内容 */}
        <div className="flex items-center gap-2 mb-1">
          <span className="badge badge-success">✅ ペア成立！</span>
          {card.memory_date && (
            <span className="text-sm text-base-content/50">{card.memory_date}</span>
          )}
        </div>

        <h3 className="font-bold text-xl mb-2">{card.title}</h3>

        {card.description && (
          <p className="text-base-content/70 text-sm leading-relaxed mb-4">
            {card.description}
          </p>
        )}

        <div className="modal-action">
          <button className="btn btn-primary w-full" onClick={onClose}>
            続ける
          </button>
        </div>
      </div>
      <div className="modal-backdrop" onClick={onClose} />
    </div>
  )
}


// ── スコアボード ────────────────────────────────
const ScoreBoard = ({ moves, pairs, total, onReset }) => (
  <div className="stats stats-horizontal shadow bg-base-100 mb-8">
    <div className="stat place-items-center">
      <div className="stat-title">手数</div>
      <div className="stat-value text-primary">{moves}</div>
      <div className="stat-desc">moves</div>
    </div>
    <div className="stat place-items-center">
      <div className="stat-title">ペア</div>
      <div className="stat-value text-secondary">
        {pairs}
        <span className="text-lg font-normal text-base-content/50"> / {total}</span>
      </div>
      <div className="stat-desc">matched</div>
    </div>
    <div className="stat place-items-center">
      <div className="stat-title">操作</div>
      <div className="stat-value">
        <button className="btn btn-ghost btn-sm text-xl" onClick={onReset}>
          🔄
        </button>
      </div>
      <div className="stat-desc">reset</div>
    </div>
  </div>
)

// ── クリアモーダル ──────────────────────────────
const ClearModal = ({ moves, total, onReset }) => (
  <div className="modal modal-open">
    <div className="modal-box text-center">
      <div className="text-6xl mb-4">🎉</div>
      <h3 className="font-bold text-2xl mb-1">クリア！</h3>
      <p className="text-base-content/70 mb-4">
        <span className="text-primary font-bold text-xl">{moves}</span>
        {" "}手でクリアしました！
      </p>
      <div className="divider" />
      <p className="text-sm text-base-content/50 mb-4">
        使用した思い出: {total}件
      </p>
      <div className="modal-action justify-center gap-3">
        <button className="btn btn-primary" onClick={onReset}>
          もう一度
        </button>
        <a href="/memories" className="btn btn-ghost">
          投稿一覧へ
        </a>
      </div>
    </div>
  </div>
)

// ── 投稿不足 ────────────────────────────────────
const InsufficientAlert = ({ needed }) => (
  <div className="card bg-base-100 shadow-xl w-full max-w-md">
    <div className="card-body items-center text-center gap-4">
      <div role="alert" className="alert alert-warning">
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2"
            d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
        </svg>
        <div className="text-left">
          <p className="font-bold">写真が足りません</p>
          <p className="text-sm">
            ゲームには最低2枚の投稿が必要です。<br />
            あと<strong>{needed}件</strong>投稿してください。
          </p>
        </div>
      </div>
      <div className="card-actions">
        <a href="/memories/new" className="btn btn-primary">思い出を投稿する</a>
        <a href="/memories" className="btn btn-ghost">投稿一覧へ</a>
      </div>
    </div>
  </div>
)

// ── メインコンポーネント ────────────────────────
export default function MemoryGame() {
  const [status, setStatus]         = useState("loading") // loading, error, insufficient, playing, clearの状態管理
  const [deck, setDeck]             = useState([]) // カードの配列
  const [needed, setNeeded]         = useState(0) // 不足しているカード枚数
  const [moves, setMoves]           = useState(0) // 手数
  const [pairs, setPairs]           = useState(0) // 揃えたペア数
  const [totalPairs, setTotalPairs] = useState(0) // 全ペア数
  const [selected, setSelected]     = useState([]) // 現在選択されているカードのindex（最大2枚まで）
  const [locked, setLocked]         = useState(false) // カードがめくられている最中は他のカードをクリックできないようにするロック状態
  const [matchedCard, setMatchedCard] = useState(null)  // マッチしたカード情報

  // カードデータをAPIから取得してデッキを構築する関数
  const fetchCards = useCallback(async () => {
    setStatus("loading")
    try {
      const res  = await fetch("/api/memory_game", {
        headers: { "X-CSRF-Token": getCsrfToken() }
      })
      const data = await res.json()

      if (!data.sufficient) {
        setNeeded(data.needed)
        setStatus("insufficient")
        return
      }

      setDeck(buildDeck(data.cards))
      setTotalPairs(data.cards.length)
      setMoves(0)
      setPairs(0)
      setSelected([])
      setLocked(false)
      setMatchedCard(null)
      setStatus("playing")
    } catch (e) {
      console.error(e)
      setStatus("error")
    }
  }, [])

  useEffect(() => { fetchCards() }, [fetchCards])

  // モーダルを閉じてゲームを再開
  const handleMatchModalClose = useCallback(() => {
    setMatchedCard(null)
    setLocked(false)  // ← モーダルを閉じたらロック解除
  }, [])

  // カードをめくる処理
  const handleFlip = useCallback((index) => {
    if (locked) return // ロックされているときは何もしない
    if (selected.includes(index)) return // すでに選択されているカードは無視

    // まだ選択されていないカードを選ぶ
    const nextSelected = [...selected, index]

    // 1枚目を選んだだけなら、カードをめくって選択状態を更新する
    if (nextSelected.length === 1) {
      setDeck(prev => prev.map(c => c.index === index ? { ...c, flipped: true } : c))
      setSelected(nextSelected)
      return
    }
    // 2枚目を選んだらまずカードをめくってからロックする
    setDeck(prev => prev.map(c => c.index === index ? { ...c, flipped: true } : c))
    setLocked(true) // 2枚目を選んだらロックして、カードの状態を見てから次のアクションを決める
    setMoves(prev => prev + 1) // 手数を1増やす

    const [firstIndex] = selected // すでに選択されているカードのindexを取得
    const firstCard  = deck.find(c => c.index === firstIndex) // そのindexに対応するカード情報をデッキから探す
    const secondCard = deck.find(c => c.index === index) // 今選んだカードの情報

    if (firstCard.id === secondCard.id) {
      // ✅ マッチ → カードをmatched状態にしてからモーダル表示
      setTimeout(() => {
        setDeck(prev =>
          prev.map(c =>
            c.index === firstIndex || c.index === index
              ? { ...c, flipped: true, matched: true }
              : c
          )
        )
        setPairs(prev => {
          const newPairs = prev + 1
          if (newPairs === totalPairs) {
            // 全ペア揃ったらクリア（モーダルは表示しない）
            setStatus("clear")
            setLocked(false)
          } else {
            // まだ続くのでマッチモーダルを表示（lockedはtrueのまま）
            setMatchedCard(firstCard)
          }
          return newPairs
        })
        setSelected([])
      }, 300)
    } else {
      // ❌ ミス
      // 900ms後にカードを元に戻して選択状態をリセット（その間はロックしたまま）
      setTimeout(() => {
        setDeck(prev =>
          prev.map(c =>
            c.index === firstIndex || c.index === index
              ? { ...c, flipped: false }
              : c
          )
        )
        setSelected([])
        setLocked(false)
      }, 900)
    }
  }, [locked, selected, deck, totalPairs])

  return (
    <div className="min-h-screen bg-base-200 flex flex-col items-center py-10 px-4">
      <h1 className="text-3xl font-bold mb-2">ミニメモリー神経衰弱🃏</h1>
      <p className="text-base-content/60 mb-8">あなたのミニメモリーをカードゲームで振り返ろう</p>

      {status === "loading" && (
        <span className="loading loading-spinner loading-lg text-primary" />
      )}

      {status === "error" && (
        <div role="alert" className="alert alert-error max-w-md">
          <span>読み込みに失敗しました。</span>
          <button className="btn btn-sm" onClick={fetchCards}>再試行</button>
        </div>
      )}

      {status === "insufficient" && <InsufficientAlert needed={needed} />}

      {(status === "playing" || status === "clear") && (
        <>
          <ScoreBoard
            moves={moves}
            pairs={pairs}
            total={totalPairs}
            onReset={fetchCards}
          />

          <div className="grid grid-cols-4 gap-3 md:gap-4 w-full max-w-2xl">
            {deck.map(card => (
              <Card key={card.index} card={card} onClick={handleFlip} />
            ))}
          </div>

          {/* マッチモーダル（ペア成立時に投稿内容を表示）*/}
          {matchedCard && (
            <MatchModal card={matchedCard} onClose={handleMatchModalClose} />
          )}

          {/* クリアモーダル */}
          {status === "clear" && (
            <ClearModal moves={moves} total={totalPairs} onReset={fetchCards} />
          )}
        </>
      )}
    </div>
  )
}
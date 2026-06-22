import React, { useEffect, useState, useCallback, useMemo, useRef } from "react"
import confetti from "canvas-confetti"

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
// React.memoでカードコンポーネントをメモ化して、propsが変わらない限り再レンダリングしないようにする
const Card = React.memo(({ card, onClick, iconPath }) => {
  const handleClick = () => {
    if (!card.flipped && !card.matched) onClick(card.index)
  }

  return (
    <button
      type="button"
      className="[perspective:800px] cursor-pointer aspect-square"
      onClick={handleClick}
      aria-label={`${card.title}をめくる`}
    >
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

        {/* 表面（変更なし）*/}
        <div
          className={[
            "absolute inset-0 rounded-2xl overflow-hidden [backface-visibility:hidden]",
            "[transform:rotateY(180deg)] shadow-md",
            card.matched ? "ring-4 ring-success ring-offset-2" : "border-2 border-base-300",
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
    </button>
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
const ClearModal = ({ moves, total, onReset }) => {
  // クリア時に画面両端から紙吹雪を約 1.5 秒間連続発射する。
  // requestAnimationFrame ループはモーダル unmount 時に active フラグで停止させる。
  // prefers-reduced-motion 設定のユーザーには紙吹雪を発射しない。
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    let active = true
    const end = Date.now() + 1500
    const colors = ["#ff6b6b", "#feca57", "#48dbfb", "#1dd1a1", "#ee5a6f", "#a55eea"]
    const tick = () => {
      if (!active) return
      confetti({ particleCount: 5, angle: 60,  spread: 55, origin: { x: 0 }, colors })
      confetti({ particleCount: 5, angle: 120, spread: 55, origin: { x: 1 }, colors })
      if (Date.now() < end) requestAnimationFrame(tick)
    }
    tick()
    return () => { active = false }
  }, [])

  return (
    <div className="modal modal-open">
      <div className="modal-box text-center motion-safe:animate-pop-in">
        <div className="text-7xl mb-3 inline-block motion-safe:animate-bounce">🎉</div>
        <h3 className="font-bold text-3xl mb-2 text-primary">やったね！</h3>
        <p className="text-base-content/80 text-lg mb-4">
          ぜんぶ あわせられたね！
        </p>

        <div className="bg-base-200 rounded-2xl px-6 py-4 mb-4 inline-block">
          <p className="text-xs text-base-content/60 mb-1">てすう</p>
          <p className="text-4xl font-bold text-primary leading-none">
            {moves}
            <span className="text-base font-normal text-base-content/70"> てで クリア</span>
          </p>
        </div>

        <p className="text-sm text-base-content/50 mb-5">
          おもいでをつかったよ: {total}まい
        </p>

        <div className="modal-action justify-center gap-3">
          <button className="btn btn-primary" onClick={onReset}>
            もういちど あそぶ
          </button>
          <a href="/memories" className="btn btn-ghost">
            おもいでをみる
          </a>
        </div>
      </div>
    </div>
  )
}

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
  // タイマー管理用のrefと、タイマーをクリアする関数を定義
  const timersRef = useRef([])

  const clearTimers = useCallback(() => {
    timersRef.current.forEach(clearTimeout)
    timersRef.current = []
  }, [])

  // iconのパスをdata属性から取得してメモ化
  const iconPath = useMemo(
    () => document.getElementById("memory-game-root")?.dataset.iconPath,
    []
  )

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
    clearTimers() // 新しいゲームを始める前にタイマーをクリアして状態をリセット
    setStatus("loading")
    try {
      const res  = await fetch("/api/memory_game", {
        headers: { "X-CSRF-Token": getCsrfToken() }
      })

      // APIリクエストが失敗した場合のエラーハンドリング
      if (!res.ok) {
        if (res.status === 401) {
          window.location.href = "/users/sign_in"
          return
        }
        throw new Error(`HTTP ${res.status}`)
      }

      // APIからのレスポンスを処理してゲームの状態を初期化
      const data = await res.json()

      // 必要なカード枚数が足りない場合は、足りない枚数を表示してゲーム開始前の状態にする
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

  useEffect(() => {
    fetchCards()
    return clearTimers
}, [fetchCards, clearTimers])

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
      const t = setTimeout(() => {
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
      timersRef.current.push(t) // タイマーIDをrefに保存しておく
    } else {
      // ❌ ミス
      // 900ms後にカードを元に戻して選択状態をリセット（その間はロックしたまま）
      const t = setTimeout(() => {
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
      timersRef.current.push(t) // タイマーIDをrefに保存しておく
    }
  }, [locked, selected, deck, totalPairs])

  return (
    <div className="min-h-screen bg-base-200 flex flex-col items-center py-10 px-4">
      <h1 className="text-3xl font-bold mb-2">おもいでカードあわせ✨</h1>
      <p className="text-base-content/60 mb-8">おなじカードを みつけてみよう！</p>

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
              <Card key={card.index} card={card} onClick={handleFlip} iconPath={iconPath} />
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
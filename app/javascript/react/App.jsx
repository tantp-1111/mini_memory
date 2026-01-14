import React from "react"

export default function App() {
  const [count, setCount] = React.useState(0)

  return (
    <div className="min-h-screen bg-base-200 p-8 flex items-center justify-center">
      <div className="card bg-base-100 shadow-xl w-full max-w-md">
        <div className="card-body">
          <h1 className="card-title text-3xl font-bold text-gray-900">
            React確認用
          </h1>

          <p className="text-gray-600">
            このコンポーネントはReactが正しく動作しているか確認するためのものです。
          </p>

          <p>
            カウント: <strong>{count}</strong>
          </p>

          <button className="btn btn-primary" onClick={() => setCount(count + 1)}>
            +1
          </button>
        </div>
      </div>
    </div>
  )
}

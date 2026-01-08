import React from 'react';
import { createRoot } from 'react-dom/client';

function App() {
  const [count, setCount] = React.useState(0);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-100 p-8 flex items-center justify-center">
      <div className="card bg-base-100 shadow-xl w-full max-w-md">
        <div className="card-body">
          <h1 className="card-title text-3xl font-bold text-gray-900">
            React確認用
          </h1>

          <div className="space-y-4">
            <p className="text-gray-600">
              このコンポーネントはReactが正しく動作しているか確認するためのものです。
            </p>

            <div className="bg-blue-50 p-4 rounded-lg">
              <p className="text-sm text-gray-700">
                カウント: <span className="font-bold text-blue-600 text-lg">{count}</span>
              </p>
            </div>

            <button
              onClick={() => setCount(count + 1)}
              className="btn btn-primary w-full"
            >
              +1
            </button>

            <button
              onClick={() => setCount(0)}
              className="btn btn-secondary w-full"
            >
              リセット
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

const root = document.getElementById('root');
if (!root) {
  throw new Error('No root element');
}
createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
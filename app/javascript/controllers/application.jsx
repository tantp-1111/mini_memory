import React from 'react';
import { createRoot } from 'react-dom/client';

function App() {
  const [count, setCount] = React.useState(0);

  return (
    <div className="bg-gradient-to-br from-purple-50 to-blue-100 p-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow-lg p-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          React確認用
        </h1>

        <div className="space-y-4">
          <p className="text-gray-600">
            このコンポーネントはReactが正しく動作しているか確認するためのものです。
          </p>

          <div className="bg-blue-50 p-4 rounded-lg">
            <p className="text-sm text-gray-700">
              カウント: <span className="font-bold text-blue-600">{count}</span>
            </p>
          </div>

          <button
            onClick={() => setCount(count + 1)}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg transition"
          >
            +1
          </button>

          <button
            onClick={() => setCount(0)}
            className="w-full bg-gray-400 hover:bg-gray-500 text-white font-bold py-2 px-4 rounded-lg transition"
          >
            リセット
          </button>
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
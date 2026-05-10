# CLAUDE.md — ミニメモリー　開発ガイド

このファイルは Claude Code がプロジェクトのコンテキストを理解するためのガイドです。

---

## ⚠️ 最重要ルール（絶対に守る）

**🚨 守らないとユーザーの学習機会を奪います**

### 授業形式・3フェーズ構造で進める

```
フェーズ1: 講義（概念解説） → フェーズ2: 質問（5問以上） → フェーズ3: 実践（Claude が実装）
```

- **フェーズ1（講義）:** 全体像 → 概念解説（処理フロー図・比較表・Before/After を活用、全体 → ファイル → メソッド単位でズームイン）
- **フェーズ2（理解確認）:** 5問以上の質問を出す → ユーザー回答（任意）→ Claude が答え合わせ・解説。回答が無い場合は Claude が正解と解説を提示
- **フェーズ3（実践）:** Claude が `git pull origin main && git pull origin develop` → `git switch -c feature/<kebab-case>` → 実装 → テスト実行 → フィードバック

小規模変更（1ファイル以内・ロジック変更なし）の場合はフェーズ2（質問）をスキップ可能

### 質問のルール

- ✅ **1 Issue あたり 5 問以上**、実装前に出す
- ✅ 7種類の質問タイプを使う：①gem/ライブラリの機能 ②Rails 規約・パターン ③設定の影響範囲 ④インフラ・Docker ⑤「なぜ?」（設計理由） ⑥「予測」（変更後の挙動） ⑦「比較」（A vs B）
- ❌ RSpec・コミット・ブランチ・PR に関する質問は不要
- **タイミング:** 新規 gem 導入 / Rails 規約利用 / 設定ファイル変更 / コントローラのアクション定義 / ルーティング設定 / ビューでヘルパー・パーシャル使用 / バリデーション・コールバック設定

### コミット前の必須作業

**🚨 `git add` 前に必ず実行:**

```bash
docker compose exec web bundle exec rubocop -a   # -A は使わない（安全な自動修正のみ）
```

### PR マージ前の確認

```bash
gh pr checks <PR番号>
```

- 全チェック（RSpec / RuboCop / Brakeman / SimpleCov）が ✅ であること
- **CI 通過前のマージは厳禁**

### コミット・PR の厳守事項

- ❌ コミットメッセージに `Co-Authored-By: Claude ...` を含めない
- ❌ PR 本文に `🤖 Generated with Claude Code` を含めない
- ⚠️ 違反時は `git commit --amend` → `git push --force` で即修正

### 実装開始のタイムリミット

GitHub Issue の実装依頼時:

- ❌ 調査・計画に 5 分以上使わない／同じファイルを 2 回以上読まない
- ✅ 5 分以内にコードを書き始める／不明点は実装しながら逐次確認／計画は 3 行以内のメンタルモデルで十分

---

## プロジェクト概要

- **アプリ名:** ミニメモリー
- **概要:** こどもの“小さな宝物の記憶”を失わないためのアプリ。子育て中に溜まる「捨てられないけど保管しきれない小さな思い出の品」を写真とエピソードで記録するサービス。
- **ターゲット:** モノにまつわる子どもの思い出を全て残したいけど物理的に保管しきれない方

---

## 技術スタック

| カテゴリ       | 技術                                       |
| -------------- | ------------------------------------------ |
| 言語 / FW      | Ruby 3.3.6 / Rails 7.2.2                   |
| 認証           | Devise + omniauth-line（LINE ログイン）    |
| フロント       | Hotwire (Turbo + Stimulus) + 一部 React 19 |
| JS / CSS       | esbuild (jsbundling-rails) / Tailwind 4 + daisyUI |
| DB             | PostgreSQL 17（本番: Neon）                |
| 画像保存       | Active Storage + Cloudinary（webp 保存）   |
| 国際化         | rails-i18n + devise-i18n                   |
| テスト         | RSpec（移行予定。既存は `test/` Minitest） |
| コンテナ       | Docker（compose.yml + Dockerfile.dev）     |
| ホスティング   | Render                                     |
| CI/CD          | GitHub Actions                             |
| 環境変数       | dotenv-rails (`.env`)                      |

**言語・命名規則:** 変数/メソッド/クラス名は英語（Rails 標準）。コミットメッセージ・コードコメント・PR タイトル/説明・Claude の応答は **日本語**。

---

## 開発ワークフロー

```
1. Issue 選定（GitHub Projects のカンバン）
2. 授業形式・3フェーズ構造で開発（最重要ルール参照）
3. RuboCop 自動修正（git add 前に必須）
4. コミット（日本語メッセージ）
5. PR 作成（gh pr create --base develop）
6. CI 通過確認 → develop へマージ
```

### Issue 選定

GitHub Issues + GitHub Projects（Backlog / In Progress / In Review / Done）で管理。

### ブランチ作成

```bash
git switch develop && git pull origin develop
git switch -c feature/<kebab-case>   # 例: feature/memory-tag-create
```

命名規則: `feature/<kebab-case>`

### コミット

タイミング: ファイル生成・削除時 / 実装が一区切り / 動作確認後 / Lint・テスト修正時

```bash
docker compose exec web bundle exec rubocop -a   # 必須
git add <変更ファイル>
git commit -m "$(cat <<'EOF'
コミットメッセージ本文
詳細な説明
EOF
)"
```

`Co-Authored-By` は付けない。

### PR 作成

**マージ先:** `develop`　**タイトル形式:** `[Feature/Fix/Refactor/...] 日本語の説明`

```bash
gh pr create --base develop --title "[Feature] タイトル" --body "$(cat <<'EOF'
## 概要
- 変更内容

## 関連 Issue
closes #XX

## 変更ファイル一覧
| ファイル | 種別 | 変更理由 |
|---------|------|---------|

## 実装のポイント

## テスト計画
- [ ]

## 残件・TODO
EOF
)"
```

PR 本文に `🤖 Generated with Claude Code` を含めない。

---

## Git 運用

### ブランチ戦略（Git Flow 簡易）

```
main      ← 本番反映（Render デプロイ対象）
develop   ← 開発統合（PR のマージ先）
feature/* ← 機能開発
hotfix/*  ← 緊急修正
```

- CI 全通過後のみ develop にマージ可（Branch Protection 設定）
- CodeRabbit (`.coderabbit.yaml`) が base: develop で自動レビュー（`WIP` / `DO NOT MERGE` / `DRAFT` ラベル / タイトルはスキップ）
- マージ後は `git checkout develop && git pull origin develop` で最新化

### .gitignore

- `.claude/` 配下と `**/CLAUDE.md` パターンは無視対象
- **例外:** プロジェクトルートの `CLAUDE.md` は既に追跡中なのでコミット可能

### マイグレーション後のチェック

- ✅ `git diff --name-only` で `db/schema.rb` が含まれることを確認してからステージング
- ❌ `db/schema.rb` なしでマイグレーション PR を作らない

---

## Claude Code 操作ガイドライン（macOS）

| コマンド                  | 実行環境       |
| ------------------------- | -------------- |
| Rails / RSpec / bundle / yarn / npm | Docker 経由    |
| git / gh                  | macOS 直接実行 |

- Docker 起動・ポート競合デバッグは明示的指示がない限り行わない
- ファイル権限が root 所有になった場合は **ユーザーに `sudo chown -R $USER:staff .` を依頼**（Claude は実行しない）
- 作成ファイルの改行コードは LF (`\n`) で統一
- 実行コマンドは必ず提示し、コピペで実行可能な形・簡潔なコメント付きにする

---

## コーディング規約

### RuboCop

- `rubocop-rails-omakase` ベース。プロジェクト固有の上書きは `.rubocop.yml`
- `git add` 前に `docker compose exec web bundle exec rubocop -a` を必ず実行

---

## テスト方針

新規テストは RSpec で記述する。

- **モデルスペック:** バリデーション / アソシエーション / スコープ / メソッド
- **リクエストスペック:** 各エンドポイントの正常系・異常系・認可
- **システムスペック:** E2E（Capybara + Selenium + headless Chrome）
- **変更のたびに即実行**（1 ファイル単位で確認、まとめて実行しない）

```bash
docker compose exec web bundle exec rspec                              # 全テスト
docker compose exec web bundle exec rspec spec/models/memory_spec.rb   # 特定ファイル
docker compose exec web bundle exec rspec spec/models/memory_spec.rb:42 # 特定行
docker compose exec web bundle exec rspec --tag focus                  # 特定タグ
```

---

## CI/CD（GitHub Actions）

`.github/workflows/ci.yml`。`pull_request` と `push`（`main` / `develop` 両方）でトリガー。

- `scan_ruby`: Brakeman でセキュリティ静的解析
- `lint`: RuboCop
- `test`: PostgreSQL サービス → `bundle exec rspec`
- `coverage`: SimpleCov で **90% 以上必須**（未満なら CI 失敗）
- 失敗時はスクリーンショットを artifact にアップロード

CI 失敗時は原因を調査・修正してからマージ。

---

## DB 設計の方針

### enum 運用

- **値は数値で固定し、後から再利用しない。** 新規 enum 追加時も新しい数値を割り当てる
  - 例: `Memory#visibility` = `private_only: 0`, `unlisted: 1`（**現在は予約・将来「家族グループメンバーのみ閲覧可能」として実装予定**）, `published: 2`
- **表示名は I18n で国際化。** 例: `Memory.visibility_options_for_select` は `enums.memory.visibility.<key>` を参照。新規追加時は `config/locales/ja.yml` に翻訳を追加
- **role 系 enum:** 例: `UserFamilyGroup#role` = `owner: 0`, `member: 1`（default は member）

### Active Storage 運用

- 画像は `has_one_attached`、本番は Cloudinary に保存
- `Memory#image` は **webp 形式で保存**（webp 想定で扱う／読み出す）
- 許可形式・サイズはモデルごとに異なるため変更時は両方確認:
  - `Memory#image`: png/jpg/jpeg/webp、最大 10MB
  - `User#avatar`: png/jpg/jpeg、最大 5MB（webp 不可）
- default 画像は `public/` 配下、`display_image` などのヘルパーで返す

### URL パラメータ

- `Memory` / `PublicMemory` / `FamilyGroup` は **`uuid` を URL パラメータとして使用**
- モデルで `to_param` を override、ルーティングで `param: :uuid`
- 新規 controller は ID 漏洩を避けるためこの慣習に従う

### マイグレーション

- `bin/rails db:prepare` は冪等（作成 + migrate + seed）
- `db/schema.rb` の追跡は Git 運用の「マイグレーション後のチェック」を参照

---

## 重要な設計判断

- **UUID URL:** 連番 ID 漏洩を避けるため、外部公開リソース（`Memory`, `PublicMemory`, `FamilyGroup`）は UUID で URL を構築
- **`Memory#visibility` の値予約:** `unlisted: 1` は将来「家族グループメンバーのみ閲覧可能」として実装予定。新規 visibility を追加する場合は `3` 以降を使う
- **1 ユーザー 1 家族グループ制約:** `UserFamilyGroup#user_id` に uniqueness。グループ移動・退出のロジック変更時はこの制約を意識
- **画像は webp で保存:** `Memory` の画像は内部的に webp。表示・配信時も webp 前提
- **認証ルーティング分岐:** 未ログインは `static_pages#top`、ログイン済みは `dashboard#top`（`authenticated :user do ... end` で分岐）
- **React の使い所:** SPA ではなく **特定機能（神経衰弱ゲーム）でのみ使用**。通常画面は ERB + Stimulus + Turbo。データ取得は `namespace :api` 配下のコントローラ。安易に React 化せず Hotwire で実装できないか先に検討
- **認可は Pundit ベース:** Policy + Scope + `authorize` / `policy_scope` で統一。`verify_authorized` 有効化済みで認可漏れを CI で検出。設計判断・公開 vs 機微情報の使い分け・race condition 対策などの詳細は [`docs/pundit-design.md`](docs/pundit-design.md) を参照

---

## その他

### 環境変数

- `dotenv-rails` で `.env` 読み込み（`.gitignore` 対象外）
- LINE OAuth: `LINE_CHANNEL_ID`, `LINE_CHANNEL_SECRET`
- Cloudinary: `config/cloudinary.yml` 参照

### 日本語化（i18n）

- `rails-i18n` + `devise-i18n`、`config.i18n.default_locale = :ja`
- プロジェクト固有の翻訳は `config/locales/` 配下
- enum の表示名も I18n 経由（DB 設計の方針参照）

### Docker コマンド

```bash
docker compose up                                       # 起動
docker compose exec web bin/rails db:create
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails console
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop -a          # git add 前に必ず
docker compose exec web bin/brakeman --no-pager
```

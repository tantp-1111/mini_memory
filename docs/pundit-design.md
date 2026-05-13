# Pundit 認可基盤 設計メモ

ミニメモリー（Rails 7.2 / Pundit）における認可基盤の構成と、設計上の判断を記録する。

---

## 段階導入

| 順 | PR | 内容 |
|---|---|---|
| 1 | #206 | gem 追加 + ApplicationController 認可基盤 |
| 2 | #208 | 各 Policy + Scope（コントローラ未適用） |
| 3 | #209 | MemoriesController に Pundit 適用 |
| 4 | #211 | FamilyGroupsController に Pundit 適用 |
| 5 | #212 | InvitationsController に Pundit 適用 |
| 6 | #213 | Dashboard / Api::MemoryGames で `policy_scope` 適用 |
| 7 | #215 | `verify_authorized` 有効化 |
| 8 | #218 | メンバーシップ管理（役割変更 / 自己脱退） |
| 9 | #220 | owner kick + 本ドキュメント追加 |
| 10 | #223 | `Memory#visibility#unlisted` を有効化（家族メンバー閲覧可） |
| 11 | #225 | 家族フィード（`FamilyFeedMemoryPolicy` + `FamilyMemoriesController`） |

各 PR を develop に積み、揃った後 main に一斉リリース。

---

## 核心となる設計判断

### 1. 認可呼び出しのパターン

本コードベースでは以下の 2 つだけを使用:

- `authorize @record` — 単一レコードへの操作可否。`authorize` を呼ぶ時点でメモリ上にインスタンスがあれば良く、DB 保存前の `Memory.new` / `current_user.memories.build(params)` も含む。Policy のメソッドは `record.user_id == user.id` のように属性を参照できる。
- `policy_scope(Model)` — index 等の一覧アクションで集合を絞り込む。

`authorize Model`（クラス渡し）は本コードベースでは使っていない。

例（`MemoriesController`）:
```ruby
def index
  @my_memories = policy_scope(Memory).with_attached_image.order(...)  # ← 一覧
end

def new
  @memory = Memory.new
  authorize @memory                                                    # ← インスタンス渡し
end

def create
  @memory = current_user.memories.build(memory_params)
  authorize @memory                                                    # ← 属性付きインスタンス
end

def set_memory
  @memory = Memory.find_by!(uuid: params[:uuid])
  authorize @memory                                                    # ← DB から取得したインスタンス
end
```

### 2. 公開情報 vs 機微情報

リソースごとに「存在自体を漏らしてよいか」で `set_xxx` のパターンを使い分けた。

| リソース | パターン | 非対象アクセス時の応答 |
|---|---|---|
| Memory | `Memory.find_by!(uuid:) + authorize` | 403 相当（`Pundit::NotAuthorizedError` → flash + redirect_back） |
| FamilyGroup | `policy_scope(FamilyGroup).find_by!(uuid:) + authorize`（**二段防衛**） | 404（`policy_scope` が空 → `find_by!` で `RecordNotFound`） |

実装根拠:
- `MemoriesController#set_memory`: `Memory.find_by!(uuid:); authorize @memory`
- `FamilyGroupsController#set_family_group`: `policy_scope(FamilyGroup).find_by!(uuid:); authorize @family_group`
- `UserFamilyGroupsController#set_family_group`: `policy_scope(FamilyGroup).find_by!(uuid: params[:family_group_uuid])`（こちらは `authorize` を別途各アクションで呼ぶ）

Memory には公開フィード（`PublicMemoriesController`）があるため非所有者の直叩きで 403 を返しても「存在自体」は機微にならない。FamilyGroup は非メンバーに存在を見せない方針なので 404 にする。

### 3. Pundit を経由しないコントローラ

以下は `skip_after_action :verify_authorized` で意図的に `authorize` 呼び出しを免除している:

| コントローラ / アクション | スキップ理由（コードコメントより） |
|---|---|
| `MemoriesController#index` | `policy_scope` のみで `authorize` を呼ばないため |
| `InvitationsController#show` | token 検証のみで Pundit を経由しない設計 |
| `DashboardController` 全体 | `policy_scope` のみで `authorize` を呼ばない |
| `Api::MemoryGamesController` 全体 | 同上 |
| `FamilyMemoriesController` 全体 | `policy_scope` のみで `authorize` を呼ばない |
| `MypagesController` 全体 | 自分自身のプロフィール表示のため認可不要 |
| `MemoryGamesController` 全体 | ゲーム画面の表示のみで認可対象レコードが無い |
| `StaticPagesController` 全体 | 未認証ランディング |
| `PublicMemoriesController` 全体 | 公開情報（`Memory.publicly_available` を直接使用） |

Devise 系コントローラは `ApplicationController` の `after_action :verify_authorized, unless: :devise_controller?` で一括除外。

### 4. 認可とビジネスルールの分離

`UserFamilyGroup` モデルの「最後の owner 保護」は Policy ではなく **モデル層の validation / before_destroy** で実装:

```ruby
# app/models/user_family_group.rb
validate :must_keep_at_least_one_owner_after_demotion, on: :update
before_destroy :ensure_at_least_one_owner_remains_after_leave
```

| レイヤ | 責務 |
|---|---|
| Pundit Policy | 「このユーザーがこの操作を実行できるか」 |
| model validation / before_destroy | 「この変更は不変条件を保てるか」 |

これにより、コントローラ以外の経路（rails console など）からも整合性が守られる。

### 5. ビューの Policy 一元化

ビューでは `policy(record).action?` を直接呼ぶ。コントローラに `@is_owner` のような真偽値を入れるインスタンス変数を作らない方針にした。

実装根拠（`app/views/family_groups/show.html.erb`）:
- 招待リンク発行カードの表示判定: `<% if policy(@family_group).update? %>`
- 解散ボタンの表示判定: `<% if policy(@family_group).destroy? %>`
- 役割変更ボタンの表示判定: `<% if policy(ufg).update? %>`
- 自己脱退ボタンの表示判定: `<% if policy(ufg).leave? %>`
- 除名ボタンの表示判定: `<% if policy(ufg).kick? %>`

`FamilyGroupsController#show` も `@is_owner` / `@current_membership` を設定していない（`@latest_invitation` のみ）。

### 6. 並行制御（コントローラ層で `lock!`）

`UserFamilyGroupsController#update` / `#destroy` は `transaction { @family_group.lock!; ... }` で family_group 行を 排他ロック:

```ruby
def update
  @membership = @family_group.user_family_groups.find(params[:id])
  authorize @membership

  succeeded = false
  ActiveRecord::Base.transaction do
    @family_group.lock!
    succeeded = @membership.update(role: params[:role])
  end
  ...
end
```

ロック対象が family_group 行である理由: 同一グループへのメンバー変更は **同じ family_group 行** を介して直列化される。各トランザクションが「異なる owner 行」を個別にロックしても両者は競合しない。グループ単位でロック。

なお model の validation / before_destroy 自体は `lock!` を呼ばない（純粋な存在判定のみ）。

### 7.　寛容な権限述語と狭い表示述語

`UserFamilyGroupPolicy` は `destroy?` を **広く** 定義し、view 用に **狭い** 述語を別途用意している:

```ruby
def destroy? = self_membership? || group_owner?    # アクション認可（self-leave + owner kick 両方を許可）
def leave?   = self_membership?                    # 自己脱退ボタン表示
def kick?    = group_owner? && !self_membership?   # 除名ボタン表示
```

`leave?` と `kick?` は条件が互いに排他的（どちらか片方しか true にならない）。`destroy?` をビューでそのまま使うと、self の行で `self_membership?` が true、かつ owner なら `group_owner?` も true になり、自分自身の行に「除名」ボタンが出てしまうため、表示判定だけは狭い述語を使う。

`UserFamilyGroupsController#destroy` は `authorize @membership` で `destroy?` を経由する。leaving_self（`@membership.user_id == current_user.id`）かどうかで成功時の redirect 先を分岐:
- self-leave 時 → `mypage_path`
- owner kick 時 → `family_group_path`

### 8. visibility ごとの閲覧範囲を `show?` に集約

`Memory#visibility` は 3 値（`private_only` / `unlisted` / `published`）。閲覧可否は `MemoryPolicy#show?` 内の論理和で表現する:

```ruby
def show? = record.published? || owner? || (record.unlisted? && family_member_of_owner?)
```

判定経路を1メソッドに集約することで、詳細ページ（`MemoriesController#show`）が visibility に関わらず同じ `authorize @memory` で動く。家族フィードから unlisted 投稿を開いても、本人が `published` を開いても、未ログインユーザーが `published` を開いても、入口は同じ。

`family_member_of_owner?` は「自分の所属グループと投稿者の所属グループに重複があるか」を 1 クエリで判定する:

```ruby
def family_member_of_owner?
  return false if user.nil?
  user.family_groups.where(id: record.user.family_groups.select(:id)).exists?
end
```

「1 ユーザー 1 グループ」制約下では実質「同じ家族グループに属しているか」と等価。`pluck` で配列に展開せずサブクエリとして渡している（DB内でクエリが完結されるため）。

### 9. Scope 専用 Policy（同一モデルで Scope を切り替える）

家族フィード（`FamilyMemoriesController#index`）は「家族メンバーが投稿した `unlisted` + `published`」を返す。これは `MemoryPolicy::Scope` の「自分の投稿のみ」とは別軸の集合。両方を `MemoryPolicy::Scope` 内で分岐させると Scope が肥大化するため、**Scope 専用の Policy** として `FamilyFeedMemoryPolicy` を切り出した:

```ruby
class FamilyFeedMemoryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      family_user_ids = UserFamilyGroup
                          .where(family_group_id: user.family_groups.select(:id))
                          .select(:user_id)
      scope.where(user_id: family_user_ids, visibility: [ :unlisted, :published ])
    end
  end
end
```

action 述語（`show?` 等）は持たない。controller 側で Pundit の `policy_scope_class:` オプションを使い、`Memory` モデルに対して別 Scope を明示指定する:

```ruby
@memories = policy_scope(Memory, policy_scope_class: FamilyFeedMemoryPolicy::Scope)
              .with_attached_image.includes(:user).order(created_at: :desc)
```

詳細ページは `MemoriesController#show` に集約する（`MemoryPolicy#show?` が家族メンバー閲覧を許可する）ため、`FamilyMemoriesController` は index のみで完結する。

---

## `verify_authorized`

`ApplicationController`:

```ruby
after_action :verify_authorized, unless: :devise_controller?
```

各アクションで `authorize` が呼ばれていない場合、Pundit が `Pundit::AuthorizationNotPerformedError` を発生させる。`Pundit::NotAuthorizedError`（実行時の認可拒否）とは別の例外で、認可呼び忘れの検出に使う。

チェック漏れを防ぐための`verify_policy_scoped` は導入していない。

---

## ファイル構成

```
app/policies/
├── application_policy.rb           基底クラス（全述語デフォルト false / Scope#resolve は NoMethodError）
├── memory_policy.rb
├── family_feed_memory_policy.rb    Scope 専用（policy_scope_class で指定）
├── family_group_policy.rb
├── user_family_group_policy.rb
└── invitation_policy.rb

app/controllers/application_controller.rb  # Pundit::Authorization include / verify_authorized / NotAuthorizedError 捕捉
config/locales/pundit.ja.yml                # 未認可メッセージ I18n
```


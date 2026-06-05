RailsAdmin.config do |config|
  config.asset_source = :sprockets

  ### Popular gems integration

  ## == Devise ==
  # ログイン必須にする（未ログインは /users/sign_in にリダイレクト）
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == 認可 ==
  # admin? が true のユーザーのみアクセス可。それ以外はトップへ戻す
  config.authorize_with do
    redirect_to main_app.root_path unless current_user&.admin?
  end

  ## == 管理対象モデル ==
  # 表示するモデルを明示的に限定（書き漏れたモデルは管理画面に出ない＝安全側）
  config.included_models = %w[User Memory FamilyGroup Child Tag Reaction]

  ## == ナビゲーションラベル ==
  config.model "User" do
    label "ユーザー"
    label_plural "ユーザー"
  end
  config.model "Memory" do
    label "ミニメモリ"
    label_plural "ミニメモリ"
  end
  config.model "FamilyGroup" do
    label "家族グループ"
    label_plural "家族グループ"
  end
  config.model "Child" do
    label "こども"
    label_plural "こども"
  end
  config.model "Tag" do
    label "タグ"
    label_plural "タグ"
  end
  config.model "Reaction" do
    label "リアクション"
    label_plural "リアクション"
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end

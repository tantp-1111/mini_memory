# Pundit Policy の基底クラス。
# 各リソースの Policy はこのクラスを継承し、`#index?` や `#update?` などの述語メソッドで
# 認可ルールを宣言する。controller 側では `authorize @record` を呼ぶことで
# 対応する Policy のメソッドが呼ばれ、false を返すと Pundit::NotAuthorizedError が発生する。
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?     = false
  def show?      = false
  def create?    = false
  def new?       = create?
  def update?    = false
  def edit?      = update?
  def destroy?   = false

  # index アクションでログインユーザーが閲覧可能なレコード集合を返す Scope。
  # `policy_scope(Model)` を controller で呼ぶと `Scope.new(current_user, Model).resolve` が走る。
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end
end

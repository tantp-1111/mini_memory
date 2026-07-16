require "rails_helper"

RSpec.describe "StaticPages", type: :request do
  it "GET / (top) は未ログインでも 200" do
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "GET /contact は 200" do
    get contact_path
    expect(response).to have_http_status(:ok)
  end

  it "GET /terms は 200" do
    get terms_path
    expect(response).to have_http_status(:ok)
  end

  it "GET /privacy は 200" do
    get privacy_path
    expect(response).to have_http_status(:ok)
  end
end

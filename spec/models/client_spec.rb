require "rails_helper"

RSpec.describe Client, type: :model do
  describe ".search_by_name(氏名・ふりがなの部分一致)" do
    let!(:tanaka) { create(:client, name: "田中 太郎", kana: "たなか たろう") }
    let!(:sato) { create(:client, name: "佐藤 花子", kana: "さとう はなこ") }

    it "氏名の一部で絞り込める" do
      expect(Client.search_by_name("田中")).to contain_exactly(tanaka)
    end

    it "ふりがなの一部で絞り込める" do
      expect(Client.search_by_name("はなこ")).to contain_exactly(sato)
    end

    it "一致しなければ空" do
      expect(Client.search_by_name("鈴木")).to be_empty
    end

    it "LIKEの特殊文字をエスケープする" do
      expect { Client.search_by_name("100%").to_a }.not_to raise_error
    end
  end
end

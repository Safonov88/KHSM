require 'rails_helper'

RSpec.describe GameQuestion, type: :model do

  let(:game_question) {FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)}

  context 'game status' do
    it 'correct .variants' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3, })
    end
    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
    end
    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  context 'correct_answer_key' do
    it 'correct key b' do
      expect(game_question.correct_answer_key).to eq 'b'
    end

    it 'correct key a' do
      game_question = FactoryGirl.create(:game_question, a: 1, b: 2, c: 4, d: 3)
      expect(game_question.correct_answer_key).to eq 'a'
    end

    it 'correct key c' do
      game_question = FactoryGirl.create(:game_question, a: 4, b: 2, c: 1, d: 3)
      expect(game_question.correct_answer_key).to eq 'c'
    end

    it 'correct key d' do
      game_question = FactoryGirl.create(:game_question, a: 3, b: 2, c: 4, d: 1)
      expect(game_question.correct_answer_key).to eq 'd'
    end
  end
end

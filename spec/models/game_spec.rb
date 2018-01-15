require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryGirl.create(:user) }

  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  let(:g) {FactoryGirl.create(:game, current_level: 2)}

  context 'Game Factory'do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      #expect(game_w_questions.previous_game_question).to eq q
      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
    it 'take_money! finishes the game' do
      # берем игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # взяли деньги
      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      # проверяем что закончилась игра и пришли деньги игроку
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end


  end

  # группа тестов на проверку статуса игры
  context '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  context '.current_game_question .previous_level' do
    it 'current_game_question'do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end

    it 'previous_level'do
      expect(g.previous_level).to eq(1)
    end
  end

  context 'answer_current_question!' do
    let(:q) { game_w_questions.current_game_question }

    it 'answer_true' do
      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_truthy
      expect(game_w_questions.status).to eq :in_progress
      expect(game_w_questions.finished?).to be_falsey

    end

    it 'answer_false' do
      expect(game_w_questions.answer_current_question!('a')).to be_falsey
      expect(game_w_questions.status).to eq :fail
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'answer_end' do
      game_w_questions.created_at = 1.hour.ago

      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_falsey
      expect(game_w_questions.status).to eq :timeout
      expect(game_w_questions.finished?).to be_truthy
    end

    it 'answer_time_end' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max

      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be_truthy
      expect(game_w_questions.status).to eq :won
      expect(game_w_questions.prize). to eq 1000000
      expect(game_w_questions.finished?).to be_truthy
    end
  end
end
